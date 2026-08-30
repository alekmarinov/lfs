#!/bin/bash
set -e
echo "Building BLFS-Mesa.."
echo "Approximate build time: 1.5 SBU"
echo "Required disk space: 700 MB"

# 24. Mesa
# The OpenGL implementation. Until now Xorg was built with glamor, dri and glx
# all off because none of this existed, so the modesetting driver ran on a
# shadow frame buffer and nothing needing GL could run at all. Mesa is what any
# real toolkit ends up wanting - gtk3 reaches it through libepoxy, which is why
# a browser cannot be built without it first.
#
# required: mako, libdrm, the xorg libraries, llvm
# https://www.linuxfromscratch.org/blfs/view/11.2/x/mesa.html
#
# BUILD_REQUIRES: x-make-mako 24-make-libdrm 24-make-xorg-libraries 13-make-llvm 8.40-make-expat 8.6-make-zlib 8.10-make-zstd 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.
#
# NOTE XORG_PREFIX comes from the file sourced below. Nothing sources
# /etc/profile.d in this build, so a script which does not read it itself sees
# an empty prefix, and meson stops with "prefix value '' must be an absolute
# path" - which is at least loud. Autotools would quietly use /usr/local.

. /etc/profile.d/xorg.sh

# NOTE -Dshared-llvm=disabled. llvm is only needed by llvmpipe, the software
# renderer swrast falls back to when there is no driver for the hardware.
# Linking it shared makes the whole llvm package a runtime dependency of the
# distro - 235 MB of clang, 99 binaries and static archives - to get at one
# 84 MB library. Linked statically, only the part llvmpipe uses ends up in the
# driver and llvm stays a build dependency, which is what it should be.
# The gallium drivers are the ones for the hardware this is tested on: nouveau
# for the nvidia cards, iris and crocus for intel graphics, and swrast, which
# is llvmpipe and the fallback wherever there is no driver. Vulkan is left out,
# nothing here uses it and it is a large part of the build. Wayland likewise -
# this distro has an X server and no compositor.
rm -rf /tmp/mesa
tar -xf /sources/mesa-*.tar.xz -C /tmp/
mv /tmp/mesa-* /tmp/mesa
pushd /tmp/mesa

mkdir build
pushd build
meson --prefix=$XORG_PREFIX \
      --buildtype=release \
      -Dgallium-drivers=nouveau,iris,crocus,swrast \
      -Dvulkan-drivers= \
      -Dplatforms=x11 \
      -Dglx=dri \
      -Degl=enabled \
      -Dgbm=enabled \
      -Dllvm=enabled \
      -Dshared-llvm=disabled \
      -Dvalgrind=disabled \
      -Dlibunwind=disabled \
      ..
ninja
ninja install

popd
popd
rm -rf /tmp/mesa

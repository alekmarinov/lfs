#!/bin/bash
set -e
echo "Building BLFS-mesa-demos (glxinfo, glxgears).."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 60 MB to build, 1 MB installed"

# 24. mesa-demos
# The package holds around three hundred OpenGL demos. Only two of them are
# installed here, and they are the reason to build it at all:
#
#   glxinfo   says which renderer is in use and whether direct rendering is on.
#             Without it there is no way to tell from inside the system whether
#             GL is running on the gpu or falling back to llvmpipe on the cpu -
#             both draw the same picture, one is a hundred times slower.
#   glxgears  draws something, which is how a broken driver is noticed.
#
# 'ninja install' is deliberately not run: it would install every demo and
# the data files that go with them for no benefit.
#
# required: mesa, glu
# https://www.linuxfromscratch.org/blfs/view/11.2/x/mesa.html
#
# BUILD_REQUIRES: 24-make-mesa 25-make-glu 24-make-xorg-libraries 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/mesa-demos
tar -xf /sources/mesa-demos-*.tar.bz2 -C /tmp/
mv /tmp/mesa-demos-* /tmp/mesa-demos
pushd /tmp/mesa-demos

# NOTE meson, not configure: 8.5.0 refuses to build with autotools, which it
# says is deprecated. Everything optional is off - the two programs installed
# below need nothing but GL and X11.
mkdir build
pushd build
meson --prefix=$XORG_PREFIX \
      --buildtype=release \
      -Dx11=enabled \
      -Degl=disabled \
      -Dgles1=disabled \
      -Dgles2=disabled \
      -Dosmesa=disabled \
      -Dlibdrm=disabled \
      -Dwayland=disabled \
      ..
ninja

install -v -m755 src/xdemos/glxinfo  /usr/bin/glxinfo
install -v -m755 src/xdemos/glxgears /usr/bin/glxgears

popd
popd
rm -rf /tmp/mesa-demos

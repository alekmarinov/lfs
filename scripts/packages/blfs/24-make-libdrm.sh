#!/bin/bash
# PACKAGE:  libdrm
# SOURCE:   libdrm-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libdrm.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 33 MB"

# 24. libdrm
# libdrm is the userspace interface to the kernel DRM drivers. The Xorg server
# includes xf86drm.h from its Linux platform support unconditionally, so it is
# required even when the server is built without DRI and GLX.
# required: libpciaccess (from the Xorg libraries)
# https://www.linuxfromscratch.org/blfs/view/11.2/x/libdrm.html

. /etc/profile.d/xorg.sh

rm -rf /tmp/libdrm
tar -xf /sources/libdrm-*.tar.xz -C /tmp/
mv /tmp/libdrm-* /tmp/libdrm
pushd /tmp/libdrm
mkdir build
pushd build
meson --prefix=$XORG_PREFIX \
      --buildtype=release \
      -Dudev=true \
      -Dvalgrind=false \
      ..
ninja
ninja install
popd
popd
rm -rf /tmp/libdrm

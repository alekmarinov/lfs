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
# NOTE valgrind=disabled, not false. libdrm turned this into a meson 'feature'
# option, which takes enabled/disabled/auto and rejects a boolean outright:
# ERROR: Value "false" (of type "string") for option "valgrind" is not one of
# the choices. udev stays a plain boolean, so it keeps true.
#
# 'meson setup' rather than bare 'meson', which meson now warns is ambiguous
# and deprecated.
meson setup --prefix=$XORG_PREFIX \
      --buildtype=release \
      -D udev=true \
      -D valgrind=disabled \
      ..
ninja
ninja install
popd
popd
rm -rf /tmp/libdrm

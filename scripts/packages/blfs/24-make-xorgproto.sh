#!/bin/bash
set -e
echo "Building BLFS-xorgproto.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 27 MB"

# 24. xorgproto
# The xorgproto package provides the header files the Xorg libraries and the
# Xorg server are built against.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xorgproto.html

. /etc/profile.d/xorg.sh

VER=$(ls /sources/xorgproto-*.tar.xz | sed 's/^[^-]*-//' | sed 's/\.tar\.xz$//')
tar -xf /sources/xorgproto-*.tar.xz -C /tmp/ \
    && mv /tmp/xorgproto-* /tmp/xorgproto \
    && pushd /tmp/xorgproto \
    && mkdir build \
    && pushd build \
    && meson --prefix=$XORG_PREFIX -Dlegacy=true .. \
    && ninja \
    && ninja install \
    && popd \
    && mv -v $XORG_PREFIX/share/doc/xorgproto{,-$VER} \
    && popd \
    && rm -rf /tmp/xorgproto \
    || exit 1

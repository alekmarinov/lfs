#!/bin/bash
# PACKAGE:  libxcvt
# SOURCE:   libxcvt-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libxcvt.."

# 24. libxcvt
# libxcvt generates the VESA CVT mode lines the Xorg server needs.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/libxcvt.html

. /etc/profile.d/xorg.sh

tar -xf /sources/libxcvt-*.tar.xz -C /tmp/ \
    && mv /tmp/libxcvt-* /tmp/libxcvt \
    && pushd /tmp/libxcvt \
    && mkdir build && pushd build \
    && meson --prefix=$XORG_PREFIX --buildtype=release .. \
    && ninja && ninja install \
    && popd && popd \
    && rm -rf /tmp/libxcvt \
    || exit 1

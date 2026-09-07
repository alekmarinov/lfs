#!/bin/bash
# PACKAGE:  xbitmaps
# SOURCE:   xbitmaps-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-xbitmaps.."

# 24. xbitmaps
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xbitmaps.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xbitmaps-*.tar.xz -C /tmp/ \
    && mv /tmp/xbitmaps-* /tmp/xbitmaps \
    && pushd /tmp/xbitmaps \
    && ./configure $XORG_CONFIG  \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/xbitmaps \
    || exit 1

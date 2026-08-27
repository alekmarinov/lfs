#!/bin/bash
set -e
echo "Building BLFS-xbitmaps.."

# 24. xbitmaps
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xbitmaps.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xbitmaps-*.tar.bz2 -C /tmp/ \
    && mv /tmp/xbitmaps-* /tmp/xbitmaps \
    && pushd /tmp/xbitmaps \
    && ./configure $XORG_CONFIG  \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/xbitmaps \
    || exit 1

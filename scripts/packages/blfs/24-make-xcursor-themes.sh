#!/bin/bash
set -e
echo "Building BLFS-xcursor-themes.."

# 24. xcursor-themes
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xcursor-themes.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xcursor-themes-*.tar.bz2 -C /tmp/ \
    && mv /tmp/xcursor-themes-* /tmp/xcursor-themes \
    && pushd /tmp/xcursor-themes \
    && ./configure $XORG_CONFIG  \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/xcursor-themes \
    || exit 1

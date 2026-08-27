#!/bin/bash
set -e
echo "Building BLFS-xinit.."

# 24. xinit
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xinit.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xinit-*.tar.bz2 -C /tmp/ \
    && mv /tmp/xinit-* /tmp/xinit \
    && pushd /tmp/xinit \
    && ./configure $XORG_CONFIG --with-xinitdir=/etc/X11/app-defaults \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/xinit \
    || exit 1

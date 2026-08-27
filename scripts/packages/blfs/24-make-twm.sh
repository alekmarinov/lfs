#!/bin/bash
set -e
echo "Building BLFS-twm.."

# 24. twm
# https://www.linuxfromscratch.org/blfs/view/11.2/x/twm.html

. /etc/profile.d/xorg.sh

tar -xf /sources/twm-*.tar.xz -C /tmp/ \
    && mv /tmp/twm-* /tmp/twm \
    && pushd /tmp/twm \
    && ./configure $XORG_CONFIG  \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/twm \
    || exit 1

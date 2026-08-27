#!/bin/bash
set -e
echo "Building BLFS-xclock.."

# 24. xclock
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xclock.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xclock-*.tar.xz -C /tmp/ \
    && mv /tmp/xclock-* /tmp/xclock \
    && pushd /tmp/xclock \
    && ./configure $XORG_CONFIG  \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/xclock \
    || exit 1

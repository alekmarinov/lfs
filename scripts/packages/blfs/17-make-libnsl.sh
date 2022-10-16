#!/bin/bash
set -e
echo "Building BLFS-libnsl.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 3.2 MB"

# 17. libnsl
# The libnsl package contains the public client interface for NIS(YP).
# It replaces the NIS library that used to be in glibc.
# Required: rpcsvc-proto,libtirpc
# https://www.linuxfromscratch.org/blfs/view/stable/basicnet/libnsl.html

tar -xf /sources/libnsl-*.tar.xz -C /tmp/ \
    && mv /tmp/libnsl-* /tmp/libnsl \
    && pushd /tmp/libnsl \
    && ./configure \
        --sysconfdir=/etc \
        --disable-static \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libnsl

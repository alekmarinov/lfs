#!/bin/bash
set -e
echo "Building BLFS-libtirpc.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 6.8 MB"

# 17. libtirpc
# The libtirpc package contains libraries that support programs that use 
# the Remote Procedure Call (RPC) API. It replaces the RPC, but not the 
# NIS library entries that used to be in glibc.
# https://www.linuxfromscratch.org/blfs/view/stable/basicnet/libtirpc.html

tar -xf /sources/libtirpc-*.tar.bz2 -C /tmp/ \
    && mv /tmp/libtirpc-* /tmp/libtirpc \
    && pushd /tmp/libtirpc \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --disable-gssapi \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libtirpc

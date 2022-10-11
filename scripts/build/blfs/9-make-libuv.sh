#!/bin/bash
set -e
echo "Building BLFS-libuv.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 14 MB"

# 9. libuv
# The libuv package is a multi-platform support library with a focus on asynchronous I/O.
# https://www.linuxfromscratch.org/blfs/view/stable/general/libuv.html

tar -xf /sources/libuv-*.tar.gz -C /tmp/ \
    && mv /tmp/libuv-* /tmp/libuv \
    && pushd /tmp/libuv \
    && sh autogen.sh \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libuv

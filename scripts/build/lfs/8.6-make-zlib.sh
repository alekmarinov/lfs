#!/bin/bash
set -e
echo "Building zlib.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 6.1 MB"

# 8.6. Zlib
# The Zlib package contains compression and decompression routines used by some programs.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/zlib.html

tar -xf /sources/zlib-*.tar.xz -C /tmp/ \
    && mv /tmp/zlib-* /tmp/zlib \
    && pushd /tmp/zlib \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    && rm -fv /usr/lib/libz.a \
    && popd \
    && rm -rf /tmp/zlib

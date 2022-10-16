#!/bin/bash
set -e
echo "Building gzip.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 11 MB"

# 6.11. Gzip
# The Gzip package contains programs for compressing and decompressing files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/gzip.html

rm -rf /tmp/gzip \
    && tar -xf gzip-*.tar.xz -C /tmp/ \
    && mv /tmp/gzip-* /tmp/gzip \
    && pushd /tmp/gzip \
    && ./configure \
        --prefix=/usr \
        --host=$LFS_TGT \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && popd \
    && rm -rf /tmp/gzip

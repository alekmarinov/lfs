#!/bin/bash
set -e
echo "Building Gzip.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 21 MB"

# 8.61. Gzip
# The Gzip package contains programs for compressing and decompressing files.
tar -xf /sources/gzip-*.tar.xz -C /tmp/ \
    && mv /tmp/gzip-* /tmp/gzip \
    && pushd /tmp/gzip \
    && ./configure --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install
    && popd \
    && rm -rf /tmp/gzip

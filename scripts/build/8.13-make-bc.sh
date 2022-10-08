#!/bin/bash
set -e
echo "Building Bc.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 7.4 MB"

# 8.13. Bc
# The Bc package contains an arbitrary precision numeric processing language.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/bc.html

tar -xf /sources/bc-*.tar.xz -C /tmp/ \
    && mv /tmp/bc-* /tmp/bc \
    && pushd /tmp/bc \
    && CC=gcc ./configure --prefix=/usr -G -O3 -r \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make test; fi \
    && make install \
    && popd \
    && rm -rf /tmp/bc

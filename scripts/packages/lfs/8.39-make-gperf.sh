#!/bin/bash
set -e
echo "Building gperf.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 6.0 MB"

# 8.37. Gperf
# Gperf generates a perfect hash function from a key set.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/gperf.html

VER=$(ls /sources/gperf-*.tar.gz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/gperf-*.tar.gz -C /tmp/ \
    && mv /tmp/gperf-* /tmp/gperf \
    && pushd /tmp/gperf \
    && ./configure \
        --prefix=/usr \
        --docdir=/usr/share/doc/gperf-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make -j1 check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/gperf

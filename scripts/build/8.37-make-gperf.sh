#!/bin/bash
set -e
echo "Building gperf.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 6.0 MB"

# 6.37. Gperf generates a perfect hash function from a key set
VER=$(ls /sources/gperf-*.tar.gz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
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

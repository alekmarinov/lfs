#!/bin/bash
set -e
echo "Building Zstd.."
echo "Approximate build time: 1.1 SBU"
echo "Required disk space: 56 MB"

# 8.9. Zstd
# Zstandard is a real-time compression algorithm, providing high compression ratios.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/zstd.html

tar -xf /sources/zstd-*.tar.gz -C /tmp/ \
    && mv /tmp/zstd-* /tmp/zstd \
    && pushd /tmp/zstd \
    && patch -Np1 -i $(ls /sources/zstd-*-upstream_fixes-1.patch) \
    && make prefix=/usr \
    && make prefix=/usr install \
    && rm -v /usr/lib/libzstd.a \
    && popd \
    && rm -rf /tmp/zstd

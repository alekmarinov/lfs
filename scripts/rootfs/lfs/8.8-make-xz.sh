#!/bin/bash
set -e
echo "Building Xz.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 16 MB"

# 8.8. Xz
# The Xz package contains programs for compressing and decompressing files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/xz.html

VER=$(ls /sources/xz-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/xz-*.tar.xz -C /tmp/ \
    && mv /tmp/xz-* /tmp/xz \
    && pushd /tmp/xz \
    && ./configure --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/xz-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/xz

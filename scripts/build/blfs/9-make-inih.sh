#!/bin/bash
set -e
echo "Building BLFS-inih.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 704 KB"

# 9. inih
# This package is a simple .INI file parser written in C.
# https://www.linuxfromscratch.org/blfs/view/stable/general/inih.html

tar -xf /sources/inih-*.tar.gz -C /tmp/ \
    && mv /tmp/inih-* /tmp/inih \
    && pushd /tmp/inih \
    && mkdir build \
    && cd build \
    && meson --prefix=/usr --buildtype=release .. \
    && ninja \
    && ninja install \
    && popd \
    && rm -rf /tmp/inih

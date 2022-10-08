#!/bin/bash
set -e
echo "Building texinfo.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 113 MB"

# 7.11. Texinfo
# The Texinfo package contains programs for reading, writing, and converting info pages.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/texinfo.html

tar -xf /sources/texinfo-*.tar.xz -C /tmp/ \
    && mv /tmp/texinfo-* /tmp/texinfo \
    && pushd /tmp/texinfo \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/texinfo

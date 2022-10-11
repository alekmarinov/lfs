#!/bin/bash
set -e
echo "Building BLFS-which.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 1 MB"

# 12. which
# GNU which package
# https://www.linuxfromscratch.org/blfs/view/stable/general/which.html

tar -xf /sources/which-*.tar.gz -C /tmp/ \
    && mv /tmp/which-* /tmp/which \
    && pushd /tmp/which \
    && ./configure \
        --prefix=/usr \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/which

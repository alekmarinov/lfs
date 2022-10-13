#!/bin/bash
set -e
echo "Building diffutils.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 163 MB"

# 6.5. Coreutils
# The Coreutils package contains utilities for showing and setting the basic
# system characteristics.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/coreutils.html

tar -xf diffutils-*.tar.xz -C /tmp/ \
    && mv /tmp/diffutils-* /tmp/diffutils \
    && pushd /tmp/diffutils \
    && ./configure --prefix=/usr --host=$LFS_TGT \
    && make \
    && make DESTDIR=$LFS install \
    && popd \
    && rm -rf /tmp/diffutils

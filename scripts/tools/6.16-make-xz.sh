#!/bin/bash
set -e
echo "Building Xz.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 16 MB"

# 6.16. Xz
# The Xz package contains programs for compressing and decompressing files.
# It provides capabilities for the lzma and the newer xz compression formats.
# Compressing text files with xz yields a better compression percentage than 
# with the traditional gzip or bzip2 commands.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/xz.html

VER=$(ls $LFS_BASE/sources/xz-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
rm -rf /tmp/xz \
    && tar -xf xz-*.tar.xz -C /tmp/ \
    && mv /tmp/xz-* /tmp/xz \
    && pushd /tmp/xz \
    && ./configure \
        --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) \
        --disable-static \
        --docdir=/usr/share/doc/xz-$VER \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && rm -v $LFS_BASE/usr/lib/liblzma.la \
    && popd \
    && rm -rf /tmp/xz

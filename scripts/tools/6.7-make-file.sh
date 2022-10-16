#!/bin/bash
set -e
echo "Building file.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 16 MB"

# 6.7. File
# The File package contains a utility for determining the type of a given file or files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/file.html

rm -rf /tmp/file \
    && tar -xf file-*.tar.gz -C /tmp/ \
    && mv /tmp/file-* /tmp/file \
    && pushd /tmp/file \
    && mkdir -v build \
    && pushd build \
    && ../configure \
        --disable-bzlib \
        --disable-libseccomp \
        --disable-xzlib \
        --disable-zlib \
    && make \
    && popd \
    && ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess) \
    && make FILE_COMPILE=$(pwd)/build/src/file \
    && make DESTDIR=$LFS_BASE install \
    && rm -v $LFS_BASE/usr/lib/libmagic.la \
    && popd \
    && rm -rf /tmp/file

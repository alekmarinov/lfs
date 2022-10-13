#!/bin/bash
set -e
echo "Building binutils.."
echo "Approximate build time: 1.4 SBU"
echo "Required disk space: 514 MB"

# 6.17. Binutils
# The Binutils package contains a linker, an assembler, and other tools for handling object files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/binutils-pass2.html

tar -xf binutils-*.tar.xz -C /tmp/ \
    && mv /tmp/binutils-* /tmp/binutils \
    && pushd /tmp/binutils \
    && sed '6009s/$add_dir//' -i ltmain.sh \
    && mkdir -v build \
    && cd build \
    && ../configure \
        --prefix=/usr \
        --build=$(../config.guess) \
        --host=$LFS_TGT \
        --disable-nls \
        --enable-shared \
        --enable-gprofng=no \
        --disable-werror \
        --enable-64-bit-bfd \
    && make \
    && make DESTDIR=$LFS install \
    && rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.{a,la} \
    && popd \
    && rm -rf /tmp/binutils

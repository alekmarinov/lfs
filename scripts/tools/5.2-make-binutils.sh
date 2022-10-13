#!/bin/bash
set -e
echo "Building binutils.."
echo "Approximate build time: 1 SBU"
echo "Required disk space: 629 MB"

# 5.2. Binutils
# The Binutils package contains a linker, an assembler, and other tools for handling object files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter05/binutils-pass1.html

tar -xf binutils-*.tar.xz -C /tmp/ \
    && mv /tmp/binutils-* /tmp/binutils \
    && pushd /tmp/binutils \
    && mkdir -v build \
    && cd build \
    && ../configure \
        --prefix=$LFS/tools \
        --with-sysroot=$LFS \
        --target=$LFS_TGT   \
        --disable-nls       \
        --enable-gprofng=no \
        --disable-werror    \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/binutils

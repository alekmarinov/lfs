#!/bin/bash
set -e
echo "Building binutils.."
echo "Approximate build time: 8.2 SBU"
echo "Required disk space: 2.7 Gb"

# 8.18. Binutils
# The Binutils package contains a linker, an assembler, and other tools for handling object files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/binutils.html

tar -xf /sources/binutils-*.tar.xz -C /tmp/ \
    && mv /tmp/binutils-* /tmp/binutils \
    && pushd /tmp/binutils \
    && expect -c "spawn ls" \
    && mkdir -v build \
    && cd build \
    && ../configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --enable-gold \
        --enable-ld=default \
        --enable-plugins \
        --enable-shared \
        --disable-werror \
        --enable-64-bit-bfd \
        --with-system-zlib \
    && make tooldir=/usr \
    && if [ $LFS_TEST -eq 1 ]; then make -k check || true; fi \
    && make tooldir=/usr install \
    && rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.a \
    && popd \
    && rm -rf /tmp/binutils

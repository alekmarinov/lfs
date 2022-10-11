#!/bin/bash
set -e
echo "Building BLFS-unzip.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 9 MB"

# 12. unzip
# The UnZip package contains ZIP extraction utilities.
# https://www.linuxfromscratch.org/blfs/view/stable/general/unzip.html

VER=$(ls /sources/unzip60.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/unzip60.tar.gz -C /tmp/ \
    && pushd /tmp/unzip \
    && patch -Np1 -i /sources/unzip-6.0-consolidated_fixes-1.patch \
    && make -f unix/Makefile generic \
    && make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install \
    && popd \
    && rm -rf /tmp/cpio

#!/bin/bash
set -e
echo "Building make.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 15 MB"

# 6.12. Make
# The Make package contains a program for controlling the generation of executables and other non-source files of a package from source files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/make.html

tar -xf make-*.tar.gz -C /tmp/ \
    && mv /tmp/make-* /tmp/make \
    && pushd /tmp/make \
    && ./configure \
        --prefix=/usr \
        --without-guile \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) \
    && make \
    && make DESTDIR=$LFS install \
    && popd \
    && rm -rf /tmp/make

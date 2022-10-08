#!/bin/bash
set -e
echo "Building make.."
echo "Approximate build time: 0.5 SBU"
echo "Required disk space: 14 MB"

# 8.65. Make
# The Make package contains a program for controlling the generation of executables and other non-source files of a package from source files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/make.html

tar -xf /sources/make-*.tar.gz -C /tmp/ \
    && mv /tmp/make-* /tmp/make \
    && pushd /tmp/make \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/make

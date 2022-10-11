#!/bin/bash
set -e
echo "Building Bison.."
echo "Approximate build time: 8.7 SBU"
echo "Required disk space: 63 MB"

# 8.32. Bison
# The Bison package contains a parser generator.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/bison.html

VER=$(ls /sources/bison-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/bison-*.tar.xz -C /tmp/ \
    && mv /tmp/bison-* /tmp/bison \
    && pushd /tmp/bison \
    && ./configure \
        --prefix=/usr \
        --docdir=/usr/share/doc/bison-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/bison

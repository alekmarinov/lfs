#!/bin/bash
set -e
echo "Building Bison.."
echo "Approximate build time: 8.7 SBU"
echo "Required disk space: 63 MB"

# 8.32. Bison
# The Bison package contains a parser generator.
VER=$(ls /sources/bison-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
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

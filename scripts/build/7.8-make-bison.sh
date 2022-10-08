#!/bin/bash
set -e
echo "Building Bison.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 57 MB"

# 7.8. Bison
# The Bison package contains a parser generator.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/bison.html

VER=$(ls /sources/bison-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/bison-*.tar.xz -C /tmp/ \
    && mv /tmp/bison-* /tmp/bison \
    && pushd /tmp/bison \
    && ./configure --prefix=/usr \
        --docdir=/usr/share/doc/bison-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/bison

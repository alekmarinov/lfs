#!/bin/bash
set -e
echo "Building Automake.."
echo "Approximate build time: less than 0.1 SBU (about 7.7 SBU with tests)"
echo "Required disk space: 116 MB"

# 8.45. Automake
# The Automake package contains programs for generating Makefiles for use with Autoconf.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/automake.html

VER=$(ls /sources/automake-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/automake-*.tar.xz -C /tmp/ \
    && mv /tmp/automake-* /tmp/automake \
    && pushd /tmp/automake \
    && ./configure \
        --prefix=/usr \
        --docdir=/usr/share/doc/automake-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make -j4 check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/automake

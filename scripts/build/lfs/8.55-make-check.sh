#!/bin/bash
set -e
echo "Building Check.."
echo "Approximate build time: 0.1 SBU (about 3.6 SBU with tests)"
echo "Required disk space: 12 MB"

# 8.55. Check
# Check is a unit testing framework for C.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/check.html

VER=$(ls /sources/check-*.tar.gz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/check-*.tar.gz -C /tmp/ \
    && mv /tmp/check-* /tmp/check \
    && pushd /tmp/check \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make docdir=/usr/share/doc/check-$VER install \
    && popd \
    && rm -rf /tmp/check

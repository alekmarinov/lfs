#!/bin/bash
set -e
echo "Building BLFS-icu.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 329 MB"

# 9. icu
# The International Components for Unicode (ICU) package is a mature, widely
# used set of C/C++ libraries providing Unicode and Globalization support for software applications. 
# optional: llvm
# https://www.linuxfromscratch.org/blfs/view/stable/general/icu.html

tar -xf /sources/icu4c-*.tgz -C /tmp/ \
    && pushd /tmp/icu \
    && cd source \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/icu

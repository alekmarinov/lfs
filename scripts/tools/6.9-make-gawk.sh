#!/bin/bash
set -e
echo "Building gawk.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 45 MB"

# 6.9. Gawk
# The Gawk package contains programs for manipulating text files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/gawk.html

rm -rf /tmp/gawk \
    && tar -xf $LFS_BASE/sources/gawk-*.tar.xz -C /tmp/ \
    && mv /tmp/gawk-* /tmp/gawk \
    && pushd /tmp/gawk \
    && sed -i 's/extras//' Makefile.in \
    && ./configure \
        --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && popd \
    && rm -rf /tmp/gawk

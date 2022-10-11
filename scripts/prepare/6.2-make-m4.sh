#!/bin/bash
set -e
echo "Building m4.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 32 MB"

# 6.2. M4
# The M4 package contains a macro processor.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/m4.html

tar -xf m4-*.tar.xz -C /tmp/ \
    && mv /tmp/m4-* /tmp/m4 \
    && pushd /tmp/m4 \
    && ./configure --prefix=/usr   \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) \
    && make \
    && make DESTDIR=$LFS install \
    && popd \
    && rm -rf /tmp/m4

#!/bin/bash
set -e
echo "Building BLFS-lzo.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 12 MB"

# 9. lzo
# LZO is a data compression library which is suitable for data decompression and compression in real-time.
# This means it favors speed over compression ratio.
# https://www.linuxfromscratch.org/blfs/view/stable/general/lzo.html

VER=$(ls /sources/lzo-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/lzo-*.tar.gz -C /tmp/ \
    && mv /tmp/lzo-* /tmp/lzo \
    && pushd /tmp/lzo \
    && ./configure \
        --prefix=/usr \
        --enable-shared \
        --disable-static \
        --docdir=/usr/share/doc/lzo-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/lzo

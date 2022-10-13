#!/bin/bash
set -e
echo "Building BLFS-libunistring.."
echo "Approximate build time: 0.7 SBU"
echo "Required disk space: 50 MB"

# 9. libunistring
# libunistring is a library that provides functions for manipulating Unicode
# strings and for manipulating C strings according to the Unicode standard.
# optional: texlive/install-tl-unx(for docs)
# https://www.linuxfromscratch.org/blfs/view/stable/general/libunistring.html

VER=$(ls /sources/libunistring-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/libunistring-*.tar.xz -C /tmp/ \
    && mv /tmp/libunistring-* /tmp/libunistring \
    && pushd /tmp/libunistring \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/libunistring-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/libunistring

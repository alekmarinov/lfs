#!/bin/bash
set -e
echo "Building BLFS-libgpg-error.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 11 MB"

# 9. libgpg-error
# The libgpg-error package contains a library that defines common error values for all GnuPG components.
# https://www.linuxfromscratch.org/blfs/view/stable/general/libgpg-error.html

VER=$(ls /sources/libgpg-error-*.tar.bz2 | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/libgpg-error-*.tar.bz2 -C /tmp/ \
    && mv /tmp/libgpg-error-* /tmp/libgpg-error \
    && pushd /tmp/libgpg-error \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && install -v -m644 -D README /usr/share/doc/libgpg-error-$VER/README \
    && popd \
    && rm -rf /tmp/libgpg-error

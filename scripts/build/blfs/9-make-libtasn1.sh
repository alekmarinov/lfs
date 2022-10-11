#!/bin/bash
set -e
echo "Building BLFS-libtasn1.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 14 MB"

# 9. libtasn1
# libtasn1 is a highly portable C library that encodes and decodes DER/BER data following an ASN.1 schema.
# optional: gtk-doc,valgrind
# https://www.linuxfromscratch.org/blfs/view/stable/general/libtasn1.html

VER=$(ls /sources/libtasn1-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/libtasn1-*.tar.gz -C /tmp/ \
    && mv /tmp/libtasn1-* /tmp/libtasn1 \
    && pushd /tmp/libtasn1 \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then make -C doc/reference install-data-local; fi \
    && popd \
    && rm -rf /tmp/libtasn1

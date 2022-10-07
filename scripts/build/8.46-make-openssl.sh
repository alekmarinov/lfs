#!/bin/bash
set -e
echo "Building OpenSSL.."
echo "Approximate build time: 5.0 SBU"
echo "Required disk space: 476 MB"

# 8.46. OpenSSL
VER=$(ls /sources/openssl-*.tar.gz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/openssl-*.tar.gz -C /tmp/ \
    && mv /tmp/openssl-* /tmp/openssl \
    && pushd /tmp/openssl \
    && ./config \
        --prefix=/usr \
        --openssldir=/etc/ssl \
        --libdir=lib \
        shared \
        zlib-dynamic \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make test || true; fi \
    && sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile \
    && make MANSUFFIX=ssl install \
    && mv -v /usr/share/doc/openssl /usr/share/doc/openssl-$VER \
    && if [ $LFS_DOCS -eq 1 ]; then \
        cp -vfr doc/* /usr/share/doc/openssl-$VER \
    fi \
    && popd \
    && rm -rf /tmp/openssl

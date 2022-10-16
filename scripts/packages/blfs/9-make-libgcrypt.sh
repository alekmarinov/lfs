#!/bin/bash
set -e
echo "Building BLFS-libgcrypt.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 130 MB"

# 9. libgcrypt
# The libgcrypt package contains a general purpose crypto library based on the
# code used in GnuPG. The library provides a high level interface to 
# cryptographic building blocks using an extendable and flexible API.
# required: libgpg-error
# optional: pth,texlive(or install-tl-unx)
# https://www.linuxfromscratch.org/blfs/view/stable/general/libgcrypt.html

VER=$(ls /sources/libgcrypt-*.tar.bz2 | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/libgcrypt-*.tar.bz2 -C /tmp/ \
    && mv /tmp/libgcrypt-* /tmp/libgcrypt \
    && pushd /tmp/libgcrypt \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_DOCS -eq 1 ]; then \
        make -C doc html \
            && makeinfo --html --no-split -o doc/gcrypt_nochunks.html doc/gcrypt.texi \
            && makeinfo --plaintext -o doc/gcrypt.txt doc/gcrypt.texi; \
        make -C doc pdf; \
    fi \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -dm755 /usr/share/doc/libgcrypt-$VER \
            && install -v -m644 README doc/{README.apichanges,fips*,libgcrypt*} \
                /usr/share/doc/libgcrypt-$VER \
            && install -v -dm755 /usr/share/doc/libgcrypt-$VER/html \
            && install -v -m644 doc/gcrypt.html/* \
                /usr/share/doc/libgcrypt-$VER/html \
            && install -v -m644 doc/gcrypt_nochunks.html \
                /usr/share/doc/libgcrypt-$VER \
            && install -v -m644 doc/gcrypt.{txt,texi} \
                /usr/share/doc/libgcrypt-$VER; \
        install -v -m644 doc/gcrypt.{pdf,ps,dvi} \
            /usr/share/doc/libgcrypt-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/libgcrypt

#!/bin/bash
set -e
echo "Building BLFS-libassuan.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 7.4 MB"

# 9. libassuan
# The libassuan package contains an inter process communication library used by 
# some of the other GnuPG related packages.
# required: libgpg-error
# optional: texlive
# https://www.linuxfromscratch.org/blfs/view/stable/general/libassuan.html

VER=$(ls /sources/libassuan-*.tar.bz2 | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/libassuan-*.tar.bz2 -C /tmp/ \
    && mv /tmp/libassuan-* /tmp/libassuan \
    && pushd /tmp/libassuan \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_DOCS -eq 1 ]; then \
        make -C doc html \
            && makeinfo --html --no-split -o doc/assuan_nochunks.html doc/assuan.texi \
            && makeinfo --plaintext -o doc/assuan.txt doc/assuan.texi; \
        make -C doc pdf ps; \
    fi \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -dm755 /usr/share/doc/libassuan-$VER/html \
        && install -v -m644 doc/assuan.html/* \
            /usr/share/doc/libassuan-$VER/html \
        && install -v -m644 doc/assuan_nochunks.html \
            /usr/share/doc/libassuan-$VER \
        && install -v -m644 doc/assuan.{txt,texi} \
            /usr/share/doc/libassuan-$VER;
        install -v -m644 doc/assuan.{pdf,ps,dvi} \
                  /usr/share/doc/libassuan-$VER;
    && popd \
    && rm -rf /tmp/libassuan

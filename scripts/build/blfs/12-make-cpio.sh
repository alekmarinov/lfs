#!/bin/bash
set -e
echo "Building BLFS-cpio.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 17 MB"

# 12. cpio
# The cpio package contains tools for archiving.
# optional: texlive
# https://www.linuxfromscratch.org/blfs/view/stable/general/cpio.html

VER=$(ls /sources/cpio-*.tar.bz2 | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/cpio-*.tar.bz2 -C /tmp/ \
    && mv /tmp/cpio-* /tmp/cpio \
    && pushd /tmp/cpio \
    && sed -i '/The name/,+2 d' src/global.c \
    && ./configure \
        --prefix=/usr \
        --enable-mt \
        --with-rmt=/usr/libexec/rmt \
    && make \
    && if [ $LFS_DOCS -eq 1 ]; then \
        makeinfo --html -o doc/html doc/cpio.texi; \
        makeinfo --html --no-split -o doc/cpio.html doc/cpio.texi; \
        makeinfo --plaintext       -o doc/cpio.txt  doc/cpio.texi; \
    fi \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -m755 -d /usr/share/doc/cpio-$VER/html; \
        install -v -m644 doc/html/* /usr/share/doc/cpio-$VER/html; \
        install -v -m644 doc/cpio.{html,txt}; /usr/share/doc/cpio-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/cpio

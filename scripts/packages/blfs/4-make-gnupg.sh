#!/bin/bash
# PACKAGE:  gnupg
# SOURCE:   gnupg-*.tar.bz2
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-gnupg.."
echo "Approximate build time: 0.7 SBU"
echo "Required disk space: 161 MB"

# 4. gnupg
# The GnuPG package is GNU's tool for secure communication and data storage. 
# required: libassuan,libgcrypt,libksba,npth
# recommended: gnutls,pinentry
# optional: curl,fuse,imagemagick,libusb,openldap,sqlite,texlive,fig2dev(for doc)
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/gnupg.html
#
# NOTE -std=gnu17. gnupg declares its own 'true' in asschk.c, which C23 turned
# into a keyword.

VER=$(ls /sources/gnupg-*.tar.bz2 | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/gnupg-*.tar.bz2 -C /tmp/ \
    && mv /tmp/gnupg-* /tmp/gnupg \
    && pushd /tmp/gnupg \
    && CC='gcc -std=gnu17' ./configure \
        --prefix=/usr \
        --localstatedir=/var \
        --sysconfdir=/etc \
        --docdir=/usr/share/doc/gnupg-$VER \
    && make \
    && makeinfo --html --no-split -o doc/gnupg_nochunks.html doc/gnupg.texi \
    && makeinfo --plaintext -o doc/gnupg.txt doc/gnupg.texi \
    && make -C doc html \
    && if [ $LFS_DOCS -eq 1 ]; then \
        make -C doc pdf ps; \
    fi \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && install -v -m755 -d /usr/share/doc/gnupg-$VER/html \
    && install -v -m644 doc/gnupg_nochunks.html \
        /usr/share/doc/gnupg-$VER/html/gnupg.html \
    && install -v -m644 doc/*.texi doc/gnupg.txt \
        /usr/share/doc/gnupg-$VER \
    && install -v -m644 doc/gnupg.html/* \
        /usr/share/doc/gnupg-$VER/html \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -m644 doc/gnupg.{pdf,dvi,ps} \
            /usr/share/doc/gnupg-$VER
    fi \
    && popd \
    && rm -rf /tmp/gnupg

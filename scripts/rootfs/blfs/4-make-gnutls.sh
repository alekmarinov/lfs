#!/bin/bash
set -e
echo "Building BLFS-gnutls.."
echo "Approximate build time: 0.9 SBU"
echo "Required disk space: 167 MB"

# 4. gnutls
# The GnuTLS package contains libraries and userspace tools which provide a secure
# layer over a reliable transport layer. Currently the GnuTLS library implements
# the proposed standards by the IETF's TLS working group.
# required: nettle
# recommended: make-ca,libunistring,libtasn1,p11-kit
# optional: brotli,doxygen,gtk-doc,guile,libidn,libidn2,libseccomp,net-tools(for tests),
#           texlive(or install-tl-unx),unbound,valgrind(for tests)
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/gnutls.html

VER=$(ls /sources/gnutls-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/gnutls-*.tar.xz -C /tmp/ \
    && mv /tmp/gnutls-* /tmp/gnutls \
    && pushd /tmp/gnutls \
    && ./configure \
        --prefix=/usr \
        --docdir=/usr/share/doc/gnutls-$VER \
        --disable-guile \
        --disable-rpath \
        --with-default-trust-store-pkcs11="pkcs11:" \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/gnutls

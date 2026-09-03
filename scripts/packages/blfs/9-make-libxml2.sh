#!/bin/bash
# PACKAGE:  libxml2
# SOURCE:   libxml2-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libxml2.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 96 MB"

# 9. libxml2
# The libxml2 package contains libraries and utilities used for parsing XML files.
# optional: icu,valgrind
# https://www.linuxfromscratch.org/blfs/view/stable/general/libxml2.html
#
# NOTE --without-python. The bindings call PyEval_CallObject(), which Python
# removed in 3.13 - the version LFS 12.4 installs. Only the Python bindings
# go; the C library every dependent here actually uses is unaffected.

VER=$(ls /sources/libxml2-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/libxml2-*.tar.xz -C /tmp/ \
    && mv /tmp/libxml2-* /tmp/libxml2 \
    && pushd /tmp/libxml2 \
    && autoreconf -fiv \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --with-history \
        --without-python \
        --docdir=/usr/share/doc/libxml2-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then \
        tar xf /sources/xmlts20130923.tar.gz; \
        make check; \
    fi \
    && make install \
    && popd \
    && rm -rf /tmp/libxml2

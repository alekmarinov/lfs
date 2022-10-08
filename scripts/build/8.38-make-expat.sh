#!/bin/bash
set -e
echo "Building Expat.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 12 MB"

# 8.38. Expat
# The Expat package contains a stream oriented C library for parsing XML.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/expat.html

VER=$(ls /sources/expat-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/expat-*.tar.xz -C /tmp/ \
    && mv /tmp/expat-* /tmp/expat \
    && pushd /tmp/expat \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/expat-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -m644 doc/*.{html,css} /usr/share/doc/expat-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/expat

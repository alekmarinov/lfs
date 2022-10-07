#!/bin/bash
set -e
echo "Building Expat.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 11 MB"

# 6.38. The Expat package contains a stream oriented C library for
# parsing XML.
VER=$(ls /sources/expat-*.tar.bz2 | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/expat-*.tar.bz2 -C /tmp/ \
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
        install -v -m644 doc/*.{html,css} /usr/share/doc/expat-$VER \
    fi \
    && popd \
    && rm -rf /tmp/expat

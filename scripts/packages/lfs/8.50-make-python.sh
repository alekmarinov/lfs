#!/bin/bash
set -e
echo "Building Python.."
echo "Approximate build time: 3.4 SBU"
echo "Required disk space: 283 MB"

# 8.50. Python
# The Python 3 package contains the Python development environment.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/Python.html
#
# BUILD_REQUIRES: 8.38-make-expat 8.49-make-libffi 8.46-make-openssl
# REBUILD_AFTER: 22-make-sqlite
#
# Python is built twice. It has to exist early because meson and ninja are
# written in it and most of the build needs them, and at that point sqlite has
# not been built yet - so setup.py finds no sqlite3.h and quietly leaves the
# _sqlite3 module out. Nothing notices until something imports it: firefox's
# mach does, and stops with "No module named '_sqlite3'".
#
# The second build, after sqlite, is what puts the module in. This is the same
# shape as freetype and harfbuzz - see order-deps.sh.

VER=$(ls /sources/Python-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/Python-*.tar.xz -C /tmp/ \
    && mv /tmp/Python-* /tmp/python \
    && pushd /tmp/python \
    && ./configure \
        --prefix=/usr \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
        --enable-optimizations \
    && make \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -dm755 /usr/share/doc/python-$VER/html; \
        tar --strip-components=1 \
            --no-same-owner \
            --no-same-permissions \
            -C /usr/share/doc/python-$VER/html \
            -xvf ../python-$VER-docs-html.tar.bz2; \
    fi \
    && popd \
    && rm -rf /tmp/python

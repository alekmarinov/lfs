#!/bin/bash
set -e
echo "Building Python.."
echo "Approximate build time: 3.4 SBU"
echo "Required disk space: 283 MB"

# 8.50. Python
# The Python 3 package contains the Python development environment.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/Python.html

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

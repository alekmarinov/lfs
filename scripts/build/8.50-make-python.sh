#!/bin/bash
set -e
echo "Building Python.."
echo "Approximate build time: 3.4 SBU"
echo "Required disk space: 283 MB"

# 8.50. Python
# The Python 3 package contains the Python development environment.
VER=$(ls /sources/Python-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/Python-*.tar.xz -C /tmp/ \
    && mv /tmp/Python-* /tmp/python \
    && pushd /tmp/python \
    && ./configure --prefix=/usr \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
        --enable-optimizations \
    && make \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -dm755 /usr/share/doc/python-$VER/html \
        tar --strip-components=1 \
            --no-same-owner \
            --no-same-permissions \
            -C /usr/share/doc/python-$VER/html \
            -xvf ../python-$VER-docs-html.tar.bz2 \
    fi \
    && popd \
    && rm -rf /tmp/python

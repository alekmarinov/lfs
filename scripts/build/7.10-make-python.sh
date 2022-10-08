#!/bin/bash
set -e
echo "Building Python.."
echo "Approximate build time: 0.9 SBU"
echo "Required disk space: 364 MB"

# 7.10. Python
# The Python 3 package contains the Python development environment. It is useful for object-oriented programming, writing scripts, prototyping large programs, or developing entire applications.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/Python.html

tar -xf /sources/Python-*.tar.xz -C /tmp/ \
    && mv /tmp/Python-* /tmp/python \
    && pushd /tmp/python \
    && ./configure --prefix=/usr \
        --enable-shared \
        --without-ensurepip \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/python

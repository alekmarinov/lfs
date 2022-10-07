#!/bin/bash
set -e
echo "Building Python.."
echo "Approximate build time: 1.2 SBU"
echo "Required disk space: 354 MB"

# 6.51. The Python 3 package contains the Python development environment. It is useful
# for object-oriented programming, writing scripts, prototyping large programs or
# developing entire applications.
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

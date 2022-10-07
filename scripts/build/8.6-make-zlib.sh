#!/bin/bash
set -e
echo "Building zlib.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 4.5 MB"

# 8.6. Zlib-1.2.12
tar -xf /sources/zlib-*.tar.xz -C /tmp/ \
  && mv /tmp/zlib-* /tmp/zlib \
  && pushd /tmp/zlib \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && rm -fv /usr/lib/libz.a \
  && popd \
  && rm -rf /tmp/zlib

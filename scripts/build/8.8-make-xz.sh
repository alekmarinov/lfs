#!/bin/bash
set -e
echo "Building Xz.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 15 MB"

# 6.45. Xz package contains programs for compressing and decompressing files.
# It provides capabilities for the lzma and the newer xz compression formats

VER=$(ls /sources/xz-*.tar.xz | grep -oP "\-[\d.]*" |  sed 's/^.\(.*\).$/\1/')
tar -xf /sources/xz-*.tar.xz -C /tmp/ \
  && mv /tmp/xz-* /tmp/xz \
  && pushd /tmp/xz \
  && ./configure --prefix=/usr \
    --disable-static \
    --docdir=/usr/share/doc/xz-$VER \
  && make \
  && make install \
  && popd \
  && rm -rf /tmp/xz

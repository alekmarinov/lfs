#!/bin/bash
# PACKAGE:  brotli
# SOURCE:   brotli-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-brotli.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 25 MB"

# brotli
# The compression woff2 fonts are compressed with. It is here for that reason
# and no other: WOFF2 is how nearly every site on the web ships its fonts, and
# a browser without it renders those pages in fallback fonts.
#
# https://github.com/google/brotli
#
# BUILD_REQUIRES: 13-make-cmake 8.56-make-ninja
# RUNTIME_REQUIRES:

rm -rf /tmp/brotli
tar -xf /sources/brotli-*.tar.gz -C /tmp/
mv /tmp/brotli-[0-9]* /tmp/brotli
pushd /tmp/brotli
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_LIBDIR=/usr/lib \
      -G Ninja \
      ..
ninja
ninja install
popd
rm -rf /tmp/brotli

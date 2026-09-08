#!/bin/bash
# PACKAGE:  woff2
# SOURCE:   woff2-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-woff2.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 15 MB"

# woff2
# Decoder for WOFF2, the web font format. WebKit's USE_WOFF2 is on by default
# and this is what satisfies it.
#
# Without it the engine still runs and pages still load - they just render in
# whatever font the system falls back to, which is the difference between a
# page that looks right and one that looks broken.
#
# https://github.com/google/woff2
#
# BUILD_REQUIRES: 9-make-brotli 13-make-cmake 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the shared library is not built by default; BUILD_SHARED_LIBS is what
# gives libwoff2dec.so, which is what WebKit looks for.

rm -rf /tmp/woff2
tar -xf /sources/woff2-*.tar.gz -C /tmp/
mv /tmp/woff2-[0-9]* /tmp/woff2
pushd /tmp/woff2
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_LIBDIR=/usr/lib \
      -DBUILD_SHARED_LIBS=ON \
      -G Ninja \
      ..
ninja
ninja install
popd
rm -rf /tmp/woff2

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
#
# NOTE '-include cstdint'. woff2 1.0.2 uses uint8_t and friends while relying
# on <cstdint> arriving transitively through another header, which GCC 13
# stopped doing - output.h fails with "'uint8_t' does not name a type" and the
# compiler names the fix itself. Ten more files in the tree have the same gap
# and happen to compile because of the order their includes land in, so this
# forces the header into every translation unit rather than patching one file
# now and the next one on the next compiler.
#
# NOTE CMAKE_POLICY_VERSION_MINIMUM. woff2 1.0.2 is from 2017 and asks for
# cmake_minimum_required(VERSION 3.0); CMake 4 removed compatibility below
# 3.5 and refuses to configure at all. This tells it to proceed under 3.5
# policies, which is what the error message itself suggests. The alternative
# is patching the upstream CMakeLists, which is a change to carry forever for
# a project that has not been released since.

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
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DCMAKE_CXX_FLAGS="-include cstdint" \
      -G Ninja \
      ..
ninja
ninja install
popd
rm -rf /tmp/woff2

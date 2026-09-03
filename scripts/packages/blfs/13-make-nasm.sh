#!/bin/bash
# PACKAGE:  nasm
# SOURCE:   nasm-*.tar.xz
# RELEASE:  1
# CLASS:    bootstrap
set -e
echo "Building BLFS-nasm.."

# nasm
# The assembler libjpeg-turbo needs for its SIMD routines, and which Firefox
# also requires. Build only - nothing runs it on the finished system.
#
# BUILD_REQUIRES: 8.69-make-make
# RUNTIME_REQUIRES:
# BUILD_ONLY: assembles libjpeg-turbo's SIMD routines at build time
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.


rm -rf /tmp/nasm
tar -xf /sources/nasm-*.tar.xz -C /tmp/
mv /tmp/nasm-* /tmp/nasm
pushd /tmp/nasm
./configure --prefix=/usr
make
make install
popd
rm -rf /tmp/nasm

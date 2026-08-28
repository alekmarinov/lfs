#!/bin/bash
set -e
echo "Building BLFS-libjpeg-turbo.."

# libjpeg-turbo
# The jpeg library. gdk-pixbuf needs it to show a jpeg, which a browser does
# constantly. Built with nasm so the SIMD paths are compiled in.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/libjpeg.html
#
# BUILD_REQUIRES: 12-make-nasm 13-make-cmake
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/libjpeg-turbo
tar -xf /sources/libjpeg-turbo-*.tar.gz -C /tmp/
mv /tmp/libjpeg-turbo-* /tmp/libjpeg-turbo
pushd /tmp/libjpeg-turbo
mkdir build
pushd build
cmake -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=RELEASE \
      -DENABLE_STATIC=FALSE \
      -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib \
      -DWITH_JPEG8=ON \
      ..
make
make install
popd
popd
rm -rf /tmp/libjpeg-turbo

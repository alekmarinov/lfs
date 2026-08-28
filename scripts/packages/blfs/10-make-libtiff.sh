#!/bin/bash
set -e
echo "Building BLFS-libtiff.."

# libtiff
# The tiff library, one of the image loaders gdk-pixbuf builds.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/libtiff.html
#
# BUILD_REQUIRES: 10-make-libjpeg-turbo 8.6-make-zlib 8.8-make-xz 13-make-cmake
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/libtiff
tar -xf /sources/tiff-*.tar.gz -C /tmp/
mv /tmp/tiff-* /tmp/libtiff
pushd /tmp/libtiff
# NOTE not 'build': the tiff tarball already contains a directory by that
# name, so mkdir fails.
mkdir libtiff-build
pushd libtiff-build
cmake -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release \
      -Dtiff-tests=OFF \
      ..
make
make install
popd
popd
rm -rf /tmp/libtiff

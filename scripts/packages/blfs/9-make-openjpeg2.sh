#!/bin/bash
# PACKAGE:  openjpeg2
# SOURCE:   openjpeg-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-OpenJPEG 2.."

# openjpeg2
# JPEG 2000 codec, used by WebKit for image decoding.
#
# NOTE the tarball is a github archive named openjpeg-x.y.z but the package is
# openjpeg2, which is how the book and every consumer refer to it.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/openjpeg2.html
#
# BUILD_REQUIRES: 13-make-cmake 9-make-lcms2 10-make-libtiff 10-make-libpng
# RUNTIME_REQUIRES:

rm -rf /tmp/openjpeg2
tar -xf /sources/openjpeg-*.tar.gz -C /tmp/
mv /tmp/openjpeg-* /tmp/openjpeg2
pushd /tmp/openjpeg2
mkdir -v build
cd build
cmake -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=/usr \
      -D BUILD_STATIC_LIBS=OFF ..
make
make install
popd
rm -rf /tmp/openjpeg2

#!/bin/bash
# PACKAGE:  libwebp
# SOURCE:   libwebp-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libwebp.."

# libwebp
# WebP image codec. WebKit decodes WebP with it, and so does anything else
# rendering modern web content.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/libwebp.html
#
# BUILD_REQUIRES: 10-make-libjpeg-turbo 10-make-libpng 10-make-libtiff
# RUNTIME_REQUIRES:

rm -rf /tmp/libwebp
tar -xf /sources/libwebp-*.tar.gz -C /tmp/
mv /tmp/libwebp-* /tmp/libwebp
pushd /tmp/libwebp
./configure --prefix=/usr \
    --enable-libwebpmux \
    --enable-libwebpdemux \
    --enable-libwebpdecoder \
    --enable-libwebpextras \
    --enable-swap-16bit-csp \
    --disable-static
make
make install
popd
rm -rf /tmp/libwebp

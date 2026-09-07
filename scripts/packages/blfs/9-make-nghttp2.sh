#!/bin/bash
# PACKAGE:  nghttp2
# SOURCE:   nghttp2-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-nghttp2.."

# nghttp2
# HTTP/2 library. libsoup requires it, which is how WPE talks to the network.
#
# NOTE --enable-lib-only. The full package also builds a server, a client and
# a proxy, which want libev, libc-ares and jansson and which nothing here
# would run.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/nghttp2.html
#
# BUILD_REQUIRES: 8.48-make-openssl
# RUNTIME_REQUIRES:

VER=$(basename "$(ls /sources/nghttp2-*.tar.xz)" .tar.xz | sed 's/^nghttp2-//')
rm -rf /tmp/nghttp2
tar -xf /sources/nghttp2-*.tar.xz -C /tmp/
mv /tmp/nghttp2-* /tmp/nghttp2
pushd /tmp/nghttp2
./configure --prefix=/usr \
    --disable-static \
    --enable-lib-only \
    --docdir=/usr/share/doc/nghttp2-$VER
make
make install
popd
rm -rf /tmp/nghttp2

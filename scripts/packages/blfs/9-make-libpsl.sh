#!/bin/bash
# PACKAGE:  libpsl
# SOURCE:   libpsl-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libpsl.."

# libpsl
# The Public Suffix List, which is how a cookie jar decides that .co.uk is not
# a domain anyone may set a cookie for. libsoup requires it.
#
# NOTE curl is deliberately built --without-libpsl in this tree, because curl
# is a core package and adding a library to the core changes the ABI id. That
# argument does not apply here: libpsl and libsoup are both class extra, so
# they can be added freely without moving the channel.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/libpsl.html
#
# BUILD_REQUIRES: 9-make-libunistring 9-make-icu 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:

rm -rf /tmp/libpsl
tar -xf /sources/libpsl-*.tar.gz -C /tmp/
mv /tmp/libpsl-* /tmp/libpsl
pushd /tmp/libpsl
mkdir build
cd build
meson setup --prefix=/usr --buildtype=release ..
ninja
ninja install
popd
rm -rf /tmp/libpsl

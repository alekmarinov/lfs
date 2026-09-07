#!/bin/bash
# PACKAGE:  libgudev
# SOURCE:   libgudev-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libgudev.."

# libgudev
# GObject bindings over libudev. WebKit uses it to notice input devices and
# removable media.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/libgudev.html
#
# BUILD_REQUIRES: 9-make-glib 8.76-make-udev 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:

rm -rf /tmp/libgudev
tar -xf /sources/libgudev-*.tar.xz -C /tmp/
mv /tmp/libgudev-* /tmp/libgudev
pushd /tmp/libgudev
mkdir build
cd build
meson setup --prefix=/usr --buildtype=release ..
ninja
ninja install
popd
rm -rf /tmp/libgudev

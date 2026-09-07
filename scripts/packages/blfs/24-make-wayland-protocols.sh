#!/bin/bash
# PACKAGE:  wayland-protocols
# SOURCE:   wayland-protocols-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-Wayland-Protocols.."

# wayland-protocols
# The XML protocol definitions compositors and clients generate code from.
# Data only - it installs no binaries and no libraries.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/wayland-protocols.html
#
# BUILD_REQUIRES: 24-make-wayland 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:

rm -rf /tmp/wayland-protocols
tar -xf /sources/wayland-protocols-*.tar.xz -C /tmp/
mv /tmp/wayland-protocols-* /tmp/wayland-protocols
pushd /tmp/wayland-protocols
mkdir build
cd build
meson setup --prefix=/usr --buildtype=release ..
ninja
ninja install
popd
rm -rf /tmp/wayland-protocols

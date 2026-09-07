#!/bin/bash
# PACKAGE:  usbutils
# SOURCE:   usbutils-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-USB Utils.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 8.5 MB"

# 12. USB Utils
# The USB Utils package contains utilities used to display information about
# USB buses in the system and the devices connected to them.
# required: libusb
# https://www.linuxfromscratch.org/blfs/view/12.4/general/usbutils.html
#
# NOTE the usb.ids database is downloaded from the network by the book, without
# it lsusb reports the numeric vendor and product ids instead of their names.

# NOTE usbutils 018 builds with meson; the autotools build was removed
# upstream. --datadir=/usr/share/hwdata went with it: meson installs usb.ids
# under the prefix, and hwdata is where the book now expects it from the
# hwdata package instead.
rm -rf /tmp/usbutils
tar -xf /sources/usbutils-*.tar.xz -C /tmp/
mv /tmp/usbutils-* /tmp/usbutils
pushd /tmp/usbutils
mkdir build
cd build
meson setup .. --prefix=/usr --buildtype=release
ninja
ninja install
popd
rm -rf /tmp/usbutils

#!/bin/bash
set -e
echo "Building BLFS-USB Utils.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 8.5 MB"

# 12. USB Utils
# The USB Utils package contains utilities used to display information about
# USB buses in the system and the devices connected to them.
# required: libusb
# https://www.linuxfromscratch.org/blfs/view/11.2/general/usbutils.html
#
# NOTE the usb.ids database is downloaded from the network by the book, without
# it lsusb reports the numeric vendor and product ids instead of their names.

tar -xf /sources/usbutils-*.tar.xz -C /tmp/ \
    && mv /tmp/usbutils-* /tmp/usbutils \
    && pushd /tmp/usbutils \
    && ./configure \
        --prefix=/usr \
        --datadir=/usr/share/hwdata \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/usbutils

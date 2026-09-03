#!/bin/bash
# PACKAGE:  libusb
# SOURCE:   libusb-*.tar.bz2
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libusb.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 12 MB"

# 9. libusb
# The libusb package contains a library used by some applications for USB device access.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/libusb.html

tar -xf /sources/libusb-*.tar.bz2 -C /tmp/ \
    && mv /tmp/libusb-* /tmp/libusb \
    && pushd /tmp/libusb \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libusb

#!/bin/bash
set -e
echo "Building BLFS-libevdev.."

# 9. libevdev
# libevdev wraps the kernel evdev interface the input drivers read from.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/libevdev.html

tar -xf /sources/libevdev-*.tar.xz -C /tmp/ \
    && mv /tmp/libevdev-* /tmp/libevdev \
    && pushd /tmp/libevdev \
    && ./configure --prefix=/usr --disable-static \
    && make && make install \
    && popd && rm -rf /tmp/libevdev \
    || exit 1

#!/bin/bash
set -e
echo "Building BLFS-mtdev.."

# 9. mtdev
# mtdev converts the kernel multitouch protocols to the slotted protocol
# libinput consumes.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/mtdev.html

tar -xf /sources/mtdev-*.tar.bz2 -C /tmp/ \
    && mv /tmp/mtdev-* /tmp/mtdev \
    && pushd /tmp/mtdev \
    && ./configure --prefix=/usr --disable-static \
    && make && make install \
    && popd && rm -rf /tmp/mtdev \
    || exit 1

#!/bin/bash
# PACKAGE:  pixman
# SOURCE:   pixman-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-Pixman.."
echo "Approximate build time: 0.4 SBU"

# 10. Pixman
# Pixman is the pixel manipulation library the Xorg server renders with.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/pixman.html

tar -xf /sources/pixman-*.tar.gz -C /tmp/ \
    && mv /tmp/pixman-* /tmp/pixman \
    && pushd /tmp/pixman \
    && mkdir build && pushd build \
    && meson --prefix=/usr --buildtype=release .. \
    && ninja && ninja install \
    && popd && popd \
    && rm -rf /tmp/pixman \
    || exit 1

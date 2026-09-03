#!/bin/bash
# PACKAGE:  libinput
# SOURCE:   libinput-*.tar.*
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libinput.."

# 9. libinput
# libinput is the input stack the Xorg driver xf86-input-libinput uses.
# required: libevdev, mtdev
# https://www.linuxfromscratch.org/blfs/view/11.2/general/libinput.html

tar -xf /sources/libinput-*.tar.* -C /tmp/ \
    && mv /tmp/libinput-* /tmp/libinput \
    && pushd /tmp/libinput \
    && mkdir build && pushd build \
    && meson --prefix=/usr --buildtype=release \
        -Ddebug-gui=false -Dtests=false -Ddocumentation=false \
        -Dlibwacom=false .. \
    && ninja && ninja install \
    && popd && popd \
    && rm -rf /tmp/libinput \
    || exit 1

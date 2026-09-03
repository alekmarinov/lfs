#!/bin/bash
# PACKAGE:  xf86-input-libinput
# SOURCE:   xf86-input-libinput-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-xf86-input-libinput.."

# 24. xf86-input-libinput
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xf86-input-libinput.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xf86-input-libinput-*.tar.xz -C /tmp/ \
    && mv /tmp/xf86-input-libinput-* /tmp/xf86-input-libinput \
    && pushd /tmp/xf86-input-libinput \
    && ./configure $XORG_CONFIG  \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/xf86-input-libinput \
    || exit 1

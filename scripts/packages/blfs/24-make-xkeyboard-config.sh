#!/bin/bash
# PACKAGE:  xkeyboard-config
# SOURCE:   xkeyboard-config-*.tar.xz
# RELEASE:  1
# GROUP:    xorg
# CLASS:    extra
set -e
echo "Building BLFS-xkeyboard-config.."

# 24. xkeyboard-config
# The keyboard layouts the Xorg server compiles with xkbcomp.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xkeyboard-config.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xkeyboard-config-*.tar.xz -C /tmp/ \
    && mv /tmp/xkeyboard-config-* /tmp/xkeyboard-config \
    && pushd /tmp/xkeyboard-config \
    && mkdir build && pushd build \
    && meson --prefix=$XORG_PREFIX --buildtype=release .. \
    && ninja \
    && ninja install \
    && popd && popd \
    && rm -rf /tmp/xkeyboard-config \
    || exit 1

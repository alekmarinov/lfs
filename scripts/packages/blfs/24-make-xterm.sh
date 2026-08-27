#!/bin/bash
set -e
echo "Building BLFS-xterm.."
echo "Approximate build time: 0.3 SBU"

# 24. xterm
# The terminal emulator the default twm session starts.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xterm.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xterm-*.tgz -C /tmp/ \
    && mv /tmp/xterm-* /tmp/xterm \
    && pushd /tmp/xterm \
    && sed -i '/v0/{n;s/new:/new:kb=^?,/}' termcap \
    && printf '\tkbs=\\177,\n' >> terminfo \
    && TERMINFO=/usr/share/terminfo ./configure \
        --prefix=$XORG_PREFIX \
        --with-app-defaults=/etc/X11/app-defaults \
    && make \
    && make install \
    && make install-ti \
    && popd && rm -rf /tmp/xterm \
    || exit 1

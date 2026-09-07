#!/bin/bash
# PACKAGE:  libXau
# SOURCE:   libXau-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libXau.."
echo "Approximate build time: less than 0.1 SBU"

# 24. libXau
# One of the Xorg build environment libraries libxcb is built against.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/libXau.html

. /etc/profile.d/xorg.sh

VER=$(ls /sources/libXau-*.tar.xz | sed 's/^[^-]*-//' | sed 's/\.tar\.bz2$//')
tar -xf /sources/libXau-*.tar.xz -C /tmp/ \
    && mv /tmp/libXau-* /tmp/libXau \
    && pushd /tmp/libXau \
    && ./configure $XORG_CONFIG --docdir=$XORG_PREFIX/share/doc/libXau-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libXau \
    || exit 1

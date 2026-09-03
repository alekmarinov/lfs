#!/bin/bash
# PACKAGE:  libXdmcp
# SOURCE:   libXdmcp-*.tar.bz2
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libXdmcp.."
echo "Approximate build time: less than 0.1 SBU"

# 24. libXdmcp
# One of the Xorg build environment libraries libxcb is built against.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/libXdmcp.html

. /etc/profile.d/xorg.sh

VER=$(ls /sources/libXdmcp-*.tar.bz2 | sed 's/^[^-]*-//' | sed 's/\.tar\.bz2$//')
tar -xf /sources/libXdmcp-*.tar.bz2 -C /tmp/ \
    && mv /tmp/libXdmcp-* /tmp/libXdmcp \
    && pushd /tmp/libXdmcp \
    && ./configure $XORG_CONFIG --docdir=$XORG_PREFIX/share/doc/libXdmcp-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libXdmcp \
    || exit 1

#!/bin/bash
# PACKAGE:  xcb-proto
# SOURCE:   xcb-proto-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-xcb-proto.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 4.5 MB"

# 24. xcb-proto
# The xcb-proto package provides the XML descriptions of the X protocol which
# libxcb generates its bindings from.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xcb-proto.html

. /etc/profile.d/xorg.sh

tar -xf /sources/xcb-proto-*.tar.xz -C /tmp/ \
    && mv /tmp/xcb-proto-* /tmp/xcb-proto \
    && pushd /tmp/xcb-proto \
    && PYTHON=python3 ./configure $XORG_CONFIG \
    && make install \
    && popd \
    && rm -rf /tmp/xcb-proto \
    || exit 1

#!/bin/bash
set -e
echo "Building BLFS-libxcb.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 68 MB"

# 24. libxcb
# The libxcb package is the C binding to the X protocol, the transport every
# Xorg library and the Xorg server speak.
# required: libXau, xcb-proto
# https://www.linuxfromscratch.org/blfs/view/11.2/x/libxcb.html

. /etc/profile.d/xorg.sh

VER=$(ls /sources/libxcb-*.tar.xz | sed 's/^[^-]*-//' | sed 's/\.tar\.xz$//')
tar -xf /sources/libxcb-*.tar.xz -C /tmp/ \
    && mv /tmp/libxcb-* /tmp/libxcb \
    && pushd /tmp/libxcb \
    && PYTHON=python3 ./configure $XORG_CONFIG \
        --without-doxygen \
        --docdir="\${datadir}/doc/libxcb-$VER" \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/libxcb \
    || exit 1

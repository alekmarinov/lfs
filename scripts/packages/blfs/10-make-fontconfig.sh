#!/bin/bash
# PACKAGE:  fontconfig
# SOURCE:   fontconfig-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-Fontconfig.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 33 MB"

# 10. Fontconfig
# The Fontconfig package contains a library and support programs used for
# configuring and customizing font access.
# required: freetype
# https://www.linuxfromscratch.org/blfs/view/11.2/general/fontconfig.html

VER=$(ls /sources/fontconfig-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9.]*$//' | sed 's/\.$//')
tar -xf /sources/fontconfig-*.tar.xz -C /tmp/ \
    && mv /tmp/fontconfig-* /tmp/fontconfig \
    && pushd /tmp/fontconfig \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-docs \
        --docdir=/usr/share/doc/fontconfig-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/fontconfig

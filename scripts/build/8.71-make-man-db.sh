#!/bin/bash
set -e
echo "Building man-db.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 40 MB"

# 8.71. Man-DB
# The Man-DB package contains programs for finding and viewing man pages.
VER=$(ls /sources/man-db-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/man-db-*.tar.xz -C /tmp/ \
    && mv /tmp/man-db-* /tmp/man-db \
    && pushd /tmp/man-db
    && ./configure \
        --prefix=/usr \
        --docdir=/usr/share/doc/man-db-$VER \
        --sysconfdir=/etc \
        --disable-setuid \
        --enable-cache-owner=bin \
        --with-browser=/usr/bin/lynx \
        --with-vgrind=/usr/bin/vgrind \
        --with-grap=/usr/bin/grap \
        --with-systemdtmpfilesdir= \
        --with-systemdsystemunitdir= \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/man-db

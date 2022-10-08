#!/bin/bash
set -e
echo "Building Util-linux.."
echo "Approximate build time: 1.0 SBU"
echo "Required disk space: 283 MB"

# 8.73. Util-linux
# The Util-linux package contains miscellaneous utility programs. Among them are utilities for handling file systems, consoles, partitions, and messages.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/util-linux.html

VER=$(ls /sources/util-linux-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/util-linux-*.tar.xz -C /tmp/ \
    && mv /tmp/util-linux-* /tmp/util-linux \
    && pushd /tmp/util-linux \
    && mkdir -pv /var/lib/hwclock \
    && ./configure \
        ADJTIME_PATH=/var/lib/hwclock/adjtime   \
        --bindir=/usr/bin    \
        --libdir=/usr/lib    \
        --sbindir=/usr/sbin  \
        --docdir=/usr/share/doc/util-linux-$(VER) \
        --disable-chfn-chsh  \
        --disable-login      \
        --disable-nologin    \
        --disable-su         \
        --disable-setpriv    \
        --disable-runuser    \
        --disable-pylibmount \
        --disable-static     \
        --without-python     \
        --without-systemd    \
        --without-systemdsystemunitdir \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/util-linux

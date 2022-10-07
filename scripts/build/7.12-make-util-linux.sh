#!/bin/bash
set -e
echo "Building Util-linux.."
echo "Approximate build time: 1.0 SBU"
echo "Required disk space: 283 MB"

# 7.12. Util-linux
# The Util-linux package contains miscellaneous utility programs. Among them are utilities for handling file systems, consoles, partitions, and messages.
VER=$(ls /sources/util-linux-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/util-linux-*.tar.xz -C /tmp/ \
    && mv /tmp/util-linux-* /tmp/util-linux \
    && pushd /tmp/util-linux \
    && mkdir -pv /var/lib/hwclock \
    && ./configure \
        ADJTIME_PATH=/var/lib/hwclock/adjtime    \
        --libdir=/usr/lib    \
        --docdir=/usr/share/doc/util-linux-$VER \
        --disable-chfn-chsh  \
        --disable-login      \
        --disable-nologin    \
        --disable-su         \
        --disable-setpriv    \
        --disable-runuser    \
        --disable-pylibmount \
        --disable-static     \
        --without-python     \
        runstatedir=/run     \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/util-linux

#!/bin/bash
set -e
echo "Building kmod.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 12 MB"

# 8.47. Kmod
# The Kmod package contains libraries and utilities for loading kernel modules
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/kmod.html
#
# NOTE kmod 34 builds with meson rather than autotools, and its configure step
# now wants scdoc to format the manual pages, so they are turned off.
#
# kmod installs the depmod/insmod/... symlinks itself, so the loop below only
# fills in whatever it did not create. They are not cosmetic: without them
# module loading at boot fails.

tar -xf /sources/kmod-*.tar.xz -C /tmp/ \
    && mv /tmp/kmod-* /tmp/kmod \
    && pushd /tmp/kmod \
    && mkdir -p build \
    && cd build \
    && meson setup --prefix=/usr .. \
        --buildtype=release \
        -D manpages=false \
    && ninja \
    && ninja install \
    && for target in depmod insmod modinfo modprobe rmmod; do \
        test -e /usr/sbin/$target || ln -sfv ../bin/kmod /usr/sbin/$target; \
    done \
    && { test -e /usr/bin/lsmod || ln -sfv kmod /usr/bin/lsmod; } \
    && popd \
    && rm -rf /tmp/kmod

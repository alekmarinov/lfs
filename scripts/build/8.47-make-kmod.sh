#!/bin/bash
set -e
echo "Building kmod.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 12 MB"

# 8.47. Kmod
# The Kmod package contains libraries and utilities for loading kernel modules
tar -xf /sources/kmod-*.tar.xz -C /tmp/ \
    && mv /tmp/kmod-* /tmp/kmod \
    && pushd /tmp/kmod \
    && ./configure --prefix=/usr \
                --sysconfdir=/etc \
                --with-openssl \
                --with-xz \
                --with-zstd \
                --with-zlib \
    && make \
    && make install \
    && for target in depmod insmod modinfo modprobe rmmod; do \
        ln -sfv ../bin/kmod /usr/sbin/$target \
    done \
    && ln -sfv kmod /usr/bin/lsmod
    && popd \
    && rm -rf /tmp/kmod

#!/bin/bash
set -e
echo "Building BLFS-reiserfsprogs.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 13 MB"

# 5. reiserfsprogs
# The reiserfsprogs package contains various utilities for use with the Reiser file system.
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/reiserfs.html

# Kernel config:
# ------------------------------------------------------------------------
# File systems --->
#   <*/M> Reiserfs support [CONFIG_REISERFS_FS]

tar -xf /sources/reiserfs-*.tar.xz -C /tmp/ \
    && mv /tmp/reiserfs-* /tmp/reiserfs \
    && pushd /tmp/reiserfs \
    && sed -i '/parse_time.h/i #define _GNU_SOURCE' lib/parse_time.c \
    && autoreconf -fiv \
    && ./configure --prefix=/usr \
    && make \
    && make install
    && popd \
    && rm -rf /tmp/reiserfs

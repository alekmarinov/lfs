#!/bin/bash
set -e
echo "Building BLFS-libarchive.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 41 MB"

# 9. libarchive
# The libarchive library provides a single interface for reading/writing various compression formats.
# optional: libxml2,lzo,nettle
# https://www.linuxfromscratch.org/blfs/view/stable/general/libarchive.html

tar -xf /sources/libarchive-*.tar.xz -C /tmp/ \
    && mv /tmp/libarchive-* /tmp/libarchive \
    && pushd /tmp/libarchive \
    && sed '/linux\/fs\.h/d' -i libarchive/archive_read_disk_posix.c \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libarchive

#!/bin/bash
set -e
echo "Building grep.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 25 MB"

# 6.10. Grep
# The Grep package contains programs for searching through the contents of files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/grep.html

rm -rf /tmp/grep \
    && tar -xf $LFS_BASE/sources/grep-*.tar.xz -C /tmp/ \
    && mv /tmp/grep-* /tmp/grep \
    && pushd /tmp/grep \
    && ./configure \
        --prefix=/usr \
        --host=$LFS_TGT \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && popd \
    && rm -rf /tmp/grep

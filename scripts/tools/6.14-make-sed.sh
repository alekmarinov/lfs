#!/bin/bash
set -e
echo "Building sed.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 20 MB"

# 6.14. Sed
# The Sed package contains a stream editor.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/sed.html

rm -rf /tmp/sed \
    && tar -xf sed-*.tar.xz -C /tmp/ \
    && mv /tmp/sed-* /tmp/sed \
    && pushd /tmp/sed \
    && ./configure \
        --prefix=/usr \
        --host=$LFS_TGT \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && popd \
    && rm -rf /tmp/sed

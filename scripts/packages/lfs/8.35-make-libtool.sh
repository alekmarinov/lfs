#!/bin/bash
set -e
echo "Building libtool.."
echo "Approximate build time: 1.5 SBU"
echo "Required disk space: 43 MB"

# 8.35. Libtool
# The Libtool package contains the GNU generic library support script. It wraps the complexity of using shared libraries in a consistent, portable interface.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/libtool.html

tar -xf /sources/libtool-*.tar.xz -C /tmp/ \
    && mv /tmp/libtool-* /tmp/libtool \
    && pushd /tmp/libtool \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && rm -fv /usr/lib/libltdl.a \
    && popd \
    && rm -rf /tmp/libtool

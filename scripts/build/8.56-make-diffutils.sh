#!/bin/bash
set -e
echo "Building diffutils.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 35 MB"

# 8.56. Diffutils
# The Diffutils package contains programs that show the differences between files or directories.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/diffutils.html

tar -xf /sources/diffutils-*.tar.xz -C /tmp/ \
    && mv /tmp/diffutils-* /tmp/diffutils \
    && pushd /tmp/diffutils \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/diffutils

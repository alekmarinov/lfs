#!/bin/bash
set -e
echo "Building patch.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 12 MB"

# 8.66. Patch
# The Patch package contains a program for modifying or creating files by applying a “patch” file typically created by the diff program.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/make.html

tar -xf /sources/patch-*.tar.xz -C /tmp/ \
    && mv /tmp/patch-* /tmp/patch \
    && pushd /tmp/patch \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/patch

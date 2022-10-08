#!/bin/bash
set -e
echo "Building libpipeline.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 10 MB"

# 8.64. Libpipeline
# The Libpipeline package contains a library for manipulating pipelines of subprocesses in a flexible and convenient way.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/libpipeline.html

tar -xf /sources/libpipeline-*.tar.gz -C /tmp/ \
    && mv /tmp/libpipeline-* /tmp/libpipeline \
    && pushd /tmp/libpipeline \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/libpipeline

#!/bin/bash
set -e
echo "Building Libffi.."
echo "Approximate build time: 1.8 SBU"
echo "Required disk space: 10 MB"

# 8.49. Libffi
# The Libffi library provides a portable, high level programming interface to various calling conventions. This allows a programmer to call any function specified by a call interface description at run time.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/libffi.html

tar -xf /sources/libffi-*.tar.gz -C /tmp/ \
    && mv /tmp/libffi-* /tmp/libffi \
    && pushd /tmp/libffi \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --with-gcc-arch=native \
        --disable-exec-static-tramp \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/libffi

#!/bin/bash
set -e
echo "Building make.."
echo "Approximate build time: 0.5 SBU"
echo "Required disk space: 14 MB"

# 8.65. Make
# The Make package contains a program for controlling the generation of executables and other non-source files of a package from source files.
tar -xf /sources/make-*.tar.bz2 -C /tmp/ \
    && mv /tmp/make-* /tmp/make \
    && pushd /tmp/make \
    && ./configure --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/make

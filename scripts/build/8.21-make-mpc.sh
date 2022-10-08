#!/bin/bash
set -e
echo "Building MPC.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 21 MB"

# 8.21. MPC
# The MPC package contains a library for the arithmetic of complex numbers
# with arbitrarily high precision and correct rounding of the result.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/mpc.html

VER=$(ls /sources/mpc-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/mpc-*.tar.gz -C /tmp/ \
    && mv /tmp/mpc-* /tmp/mpc \
    && pushd /tmp/mpc \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/mpc-$VER \
    && make \
    && make html \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then make install-html; fi \
    && popd \
    && rm -rf /tmp/mpc

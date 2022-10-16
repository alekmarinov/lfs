#!/bin/bash
set -e
echo "Building GMP.."
echo "Approximate build time: 0.9 SBU"
echo "Required disk space: 53 MB"

# 8.19. GMP
# The GMP package contains math libraries. These have useful functions for arbitrary precision arithmetic.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/gmp.html

VER=$(ls /sources/gmp-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/gmp-*.tar.xz -C /tmp/ \
    && mv /tmp/gmp-* /tmp/gmp \
    && pushd /tmp/gmp \
    && ./configure \
        --prefix=/usr \
        --enable-cxx \
        --disable-static \
        --docdir=/usr/share/doc/gmp-$VER \
    && make \
    && make html \
    && if [ $LFS_TEST -eq 1 ]; then \
        make check 2>&1 | tee gmp-check-log; \
        awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log; \
    fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then make install-html; fi \
    && popd \
    && rm -rf /tmp/gmp

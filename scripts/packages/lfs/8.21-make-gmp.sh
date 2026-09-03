#!/bin/bash
# PACKAGE:  gmp
# SOURCE:   gmp-*.tar.xz
# RELEASE:  1
# CLASS:    system
set -e
echo "Building GMP.."
echo "Approximate build time: 0.9 SBU"
echo "Required disk space: 53 MB"

# 8.19. GMP
# The GMP package contains math libraries. These have useful functions for arbitrary precision arithmetic.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/gmp.html
#
# NOTE the sed is the book's gcc-15 compatibility fix. One of configure's own
# probe programs declares 'g()' and then calls it with arguments. Under C23,
# which GCC 15 defaults to, '()' means 'no parameters' rather than
# 'unspecified', so the probe fails to compile and configure concludes there
# is no working compiler at all.

VER=$(ls /sources/gmp-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/gmp-*.tar.xz -C /tmp/ \
    && mv /tmp/gmp-* /tmp/gmp \
    && pushd /tmp/gmp \
    && sed -i '/long long t1;/,+1s/()/(...)/' configure \
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

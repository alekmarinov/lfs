#!/bin/bash
set -e
echo "Building diffutils.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 163 MB"

# 6.5. Coreutils
# The Coreutils package contains utilities for showing and setting the basic
# system characteristics.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/coreutils.html
#
# NOTE gl_cv_func_strcasecmp_works=y. diffutils 3.12 probes strcasecmp by
# running a test program, which cannot be done while cross compiling, and
# configure stops. The book answers the probe up front instead. --build is
# given for the same reason the book gives it.

rm -rf /tmp/diffutils \
    && tar -xf $LFS_BASE/sources/diffutils-*.tar.xz -C /tmp/ \
    && mv /tmp/diffutils-* /tmp/diffutils \
    && pushd /tmp/diffutils \
    && ./configure --prefix=/usr --host=$LFS_TGT \
        gl_cv_func_strcasecmp_works=y \
        --build=$(./build-aux/config.guess) \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && popd \
    && rm -rf /tmp/diffutils

#!/bin/bash
# PACKAGE:  bc
# SOURCE:   bc-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building Bc.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 7.4 MB"

# 8.13. Bc
# The Bc package contains an arbitrary precision numeric processing language.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/bc.html
#
# NOTE -std=c99. GCC 15 defaults to C23, where 'true' and 'false' are
# keywords rather than stdbool macros. bc pastes them onto a suffix with
# UINTMAX_C(), and unexpanded they paste into 'trueUL' and 'falseUL'.

tar -xf /sources/bc-*.tar.xz -C /tmp/ \
    && mv /tmp/bc-* /tmp/bc \
    && pushd /tmp/bc \
    && CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make test; fi \
    && make install \
    && popd \
    && rm -rf /tmp/bc

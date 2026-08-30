#!/bin/bash
set -e
echo "Building libxcrypt.."

# 8.27. libxcrypt
# glibc no longer provides libcrypt, so it comes from here. Built twice: the
# second pass installs only libcrypt.so.1, the compatibility library which
# anything built against the old glibc still asks for.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/libxcrypt.html
#
# BUILD_REQUIRES: 8.69-make-make
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/libxcrypt
tar -xf /sources/libxcrypt-*.tar.xz -C /tmp/
mv /tmp/libxcrypt-* /tmp/libxcrypt
pushd /tmp/libxcrypt
./configure --prefix=/usr \
    --enable-hashes=strong,glibc \
    --enable-obsolete-api=no \
    --disable-static \
    --disable-failure-tokens
make
make install

make distclean
./configure --prefix=/usr \
    --enable-hashes=strong,glibc \
    --enable-obsolete-api=glibc \
    --disable-static \
    --disable-failure-tokens
make
cp -av --remove-destination .libs/libcrypt.so.1* /usr/lib
popd
rm -rf /tmp/libxcrypt

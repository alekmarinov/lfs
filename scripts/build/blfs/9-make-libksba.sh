#!/bin/bash
set -e
echo "Building BLFS-libksba.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 9.3 MB"

# 9. libksba
# The Libksba package contains a library used to make X.509 certificates as well
# as making the CMS (Cryptographic Message Syntax) easily accessible by other applications. 
# required: libgpg-error
# optional: valgrind
#https://www.linuxfromscratch.org/blfs/view/svn/general/libksba.html

VER=$(ls /sources/libksba-*.tar.bz2 | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/libksba-*.tar.bz2 -C /tmp/ \
    && mv /tmp/libksba-* /tmp/libksba \
    && pushd /tmp/libksba \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/libksba

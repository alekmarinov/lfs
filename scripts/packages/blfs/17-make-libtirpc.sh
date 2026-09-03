#!/bin/bash
# PACKAGE:  libtirpc
# SOURCE:   libtirpc-*.tar.bz2
# RELEASE:  1
# CLASS:    core
set -e
echo "Building BLFS-libtirpc.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 6.8 MB"

# 17. libtirpc
# The libtirpc package contains libraries that support programs that use 
# the Remote Procedure Call (RPC) API. It replaces the RPC, but not the 
# NIS library entries that used to be in glibc.
# https://www.linuxfromscratch.org/blfs/view/stable/basicnet/libtirpc.html
#
# NOTE -std=gnu17. libtirpc declares xdr_opaque_auth() and others with empty
# parentheses, which C23 reads as 'takes no arguments' rather than
# 'unspecified', so its own calls to them stop compiling.

tar -xf /sources/libtirpc-*.tar.bz2 -C /tmp/ \
    && mv /tmp/libtirpc-* /tmp/libtirpc \
    && pushd /tmp/libtirpc \
    && CC='gcc -std=gnu17' ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --disable-gssapi \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libtirpc

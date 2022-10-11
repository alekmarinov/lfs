#!/bin/bash
set -e
echo "Building BLFS-liburcu.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 22 MB"

# 9. liburcu
# The userspace-rcu package provides a set of userspace RCU (read-copy-update) libraries. 
# https://www.linuxfromscratch.org/blfs/view/stable/general/liburcu.html

VER=$(ls /sources/userspace-rcu-*.tar.bz2 | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/userspace-rcu-*.tar.bz2 -C /tmp/ \
    && mv /tmp/userspace-rcu-* /tmp/liburcu \
    && pushd /tmp/liburcu \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/liburcu-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/liburcu

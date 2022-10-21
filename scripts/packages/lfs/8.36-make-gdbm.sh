#!/bin/bash
set -e
echo "Building GDBM.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 13 MB"

# 8.36. GDBM
# The GDBM package contains the GNU Database Manager.
# It is a library of database functions that use extensible hashing and works
# similar to the standard UNIX dbm. The library provides primitives for storing
# key/data pairs, searching and retrieving the data by its key and deleting a
# key along with its data.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/gdbm.html

tar -xf /sources/gdbm-*.tar.gz -C /tmp/ \
    && mv /tmp/gdbm-* /tmp/gdbm \
    && pushd /tmp/gdbm \
    && ./configure \
        --prefix=/usr    \
        --disable-static \
        --enable-libgdbm-compat \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/gdbm

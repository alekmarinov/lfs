#!/bin/bash
set -e
echo "Building BLFS-gdb.."
echo "Approximate build time: 1.8 SBU"
echo "Required disk space: 716 MB"

# 13. gdb
# GDB, the GNU Project debugger, allows you to see what is going on “inside” another
# program while it executes -- or what another program was doing at the moment it crashed.
# recommended: six
# https://www.linuxfromscratch.org/blfs/view/stable/general/gdb.html

VER=$(ls /sources/gdb-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/gdb-*.tar.xz -C /tmp/ \
    && mv /tmp/gdb-* /tmp/gdb \
    && pushd /tmp/gdb \
    && mkdir build \
    && cd build \
    && ../configure \
        --prefix=/usr \
        --with-system-readline \
        --with-python=/usr/bin/python3 \
    && make \
    && if [ $LFS_DOCS -eq 1 ]; then make -C gdb/doc doxy; fi \
    && if [ $LFS_TEST -eq 1 ]; then \
        pushd gdb/testsuite; \
        make site.exp; \
        echo "set gdb_test_timeout 120" >> site.exp; \
        runtest; \
        popd; \
    fi \
    && make -C gdb install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -d /usr/share/doc/gdb-$VER; \
        rm -rf gdb/doc/doxy/xml; \
        cp -Rv gdb/doc/doxy /usr/share/doc/gdb-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/gdb

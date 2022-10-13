#!/bin/bash
set -e
echo "Building BLFS-valgrind.."
echo "Approximate build time: 0.5 SBU"
echo "Required disk space: 382 MB"

# 13. valgrind
# Valgrind is an instrumentation framework for building dynamic analysis tools.
# https://www.linuxfromscratch.org/blfs/view/stable/general/valgrind.html

tar -xf /sources/valgrind-*.tar.bz2 -C /tmp/ \
    && mv /tmp/valgrind-* /tmp/valgrind \
    && pushd /tmp/valgrind \
    && sed -i 's|/doc/valgrind||' docs/Makefile.in \
    && ./configure \
        --prefix=/usr \
        --datadir=/usr/share/doc/valgrind-3.19.0 \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then \
        sed -e 's@prereq:.*@prereq: false@' \
            -i {helgrind,drd}/tests/pth_cond_destroy_busy.vgtest; \
        make regtest; \
    fi \
    && make install \
    && popd \
    && rm -rf /tmp/valgrind

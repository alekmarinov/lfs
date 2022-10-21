#!/bin/bash
set -e
echo "Building BLFS-npth.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 2.6 MB"

# 9. npth
# The NPth package contains a very portable POSIX/ANSI-C based library for Unix
# platforms which provides non-preemptive priority-based scheduling for 
# multiple threads of execution (multithreading) inside event-driven applications. 
# https://www.linuxfromscratch.org/blfs/view/svn/general/npth.html

VER=$(ls /sources/npth-*.tar.bz2 | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/npth-*.tar.bz2 -C /tmp/ \
    && mv /tmp/npth-* /tmp/npth \
    && pushd /tmp/npth \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/npth

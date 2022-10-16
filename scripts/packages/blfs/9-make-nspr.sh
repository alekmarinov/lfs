#!/bin/bash
set -e
echo "Building BLFS-nspr.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 9.6 MB"

# 9. nspr
# Netscape Portable Runtime (NSPR) provides a platform-neutral API for system level and libc like functions.
# https://www.linuxfromscratch.org/blfs/view/stable/general/nspr.html

tar -xf /sources/nspr-*.tar.gz -C /tmp/ \
    && mv /tmp/nspr-* /tmp/nspr \
    && pushd /tmp/nspr \
    && cd nspr \
    && sed -ri '/^RELEASE/s/^/#/' pr/src/misc/Makefile.in \
    && sed -i 's#$(LIBRARY) ##'   config/rules.mk \
    && ./configure \
        --prefix=/usr \
        --with-mozilla \
        --with-pthreads \
        $([ $(uname -m) = x86_64 ] && echo --enable-64bit) \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/nspr

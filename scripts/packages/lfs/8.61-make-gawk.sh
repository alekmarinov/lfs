#!/bin/bash
set -e
echo "Building gawk.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 44 MB"

# 8.57. Gawk
# The Gawk package contains programs for manipulating text files.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/gawk.html

VER=$(ls /sources/gawk-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/gawk-*.tar.xz -C /tmp/ \
    && mv /tmp/gawk-* /tmp/gawk \
    && pushd /tmp/gawk \
    && sed -i 's/extras//' Makefile.in \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        mkdir -v /usr/share/doc/gawk-$VER; \
        cp -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/gawk

# gawk's own 'make install' creates this symlink, and that is not enough. A
# package is the diff of its build, so a link 'make install' skips because it
# is already in the base layer is not captured - which is exactly what
# happened: /usr/bin/awk has been in overlay/base since 2026-08-29 and in no
# package since. Every distro that installed gawk got gawk and no awk.
#
# 'ln -sf' replaces the link whether or not it is there, so it always writes
# and is always in the diff. Explicit, and immune to the base layer's state.
ln -sfv gawk /usr/bin/awk

test -L /usr/bin/awk || { echo "/usr/bin/awk was not created"; exit 1; }

#!/bin/bash
set -e
echo "Building tar.."
echo "Approximate build time: 1.7 SBU"
echo "Required disk space: 40 MB"

# 8.67. Tar
# The Tar package provides the ability to create tar archives as well as
# perform various other kinds of archive manipulation. Tar can be used on
# previously created archives to extract files, to store additional files,
# or to update or list files which were already stored.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/tar.html

VER=$(ls /sources/tar-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/tar-*.tar.xz -C /tmp/ \
    && mv /tmp/tar-* /tmp/tar \
    && pushd /tmp/tar \
    && FORCE_UNSAFE_CONFIGURE=1 ./configure \
        --prefix=/usr \
        --bindir=/bin \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        make -C doc install-html docdir=/usr/share/doc/tar-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/tar

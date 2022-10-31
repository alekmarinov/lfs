#!/bin/bash
set -e
echo "Building Attr.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 4.1 MB"

# 8.22. Attr
# The attr package contains utilities to administer the extended attributes on filesystem objects.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/attr.html

VER=$(ls /sources/attr-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/attr-*.tar.gz -C /tmp/ \
    && mv /tmp/attr-* /tmp/attr \
    && pushd /tmp/attr \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --sysconfdir=/etc \
        --docdir=/usr/share/doc/attr-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/attr

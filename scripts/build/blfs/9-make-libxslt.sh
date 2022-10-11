#!/bin/bash
set -e
echo "Building BLFS-libxslt.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 35 MB"

# 9. libxslt
# The libxslt package contains XSLT libraries used for extending libxml2 libraries to support XSLT files.
# required: libxml2
# recommended: docbook-xml,docbook-xsl-nons (runtime)
# optional: libgcrypt,python2,libxml2
# https://www.linuxfromscratch.org/blfs/view/stable/general/libxslt.html

VER=$(ls /sources/libxslt-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/libxslt-*.tar.xz -C /tmp/ \
    && mv /tmp/libxslt-* /tmp/libxslt \
    && pushd /tmp/libxslt \
    && sed -i s/3000/5000/ libxslt/transform.c doc/xsltproc.{1,xml} \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --without-python \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/libxslt

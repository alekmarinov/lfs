#!/bin/bash
set -e
echo "Building BLFS-sgml-common.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 1.5 MB"

# 48. sgml-common
# The SGML Common package contains install-catalog.
# This is useful for creating and maintaining centralized SGML catalogs.
# https://www.linuxfromscratch.org/blfs/view/stable/pst/sgml-common.html

VER=$(ls /sources/sgml-common-*.tgz |  sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/sgml-common-*.tgz -C /tmp/ \
    && mv /tmp/sgml-common-* /tmp/sgml-common \
    && pushd /tmp/sgml-common \
    && patch -Np1 -i /sources/sgml-common-0.6.3-manpage-1.patch \
    && autoreconf -f -i \
    && ./configure --prefix=/usr --sysconfdir=/etc \
    && make \
    && make docdir=/usr/share/doc install \
    && install-catalog --add /etc/sgml/sgml-ent.cat \
        /usr/share/sgml/sgml-iso-entities-8879.1986/catalog \
    && install-catalog --add /etc/sgml/sgml-docbook.cat \
        /etc/sgml/sgml-ent.cat \
    && popd \
    && rm -rf /tmp/sgml-common

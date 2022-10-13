#!/bin/bash
set -e
echo "Building pkg config.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 29 MB"

# 8.27. Pkg-config
# The pkg-config package contains a tool for passing the include path and/or
# library paths to build tools during the configure and make phases of package installations.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/pkg-config.html

VER=$(ls /sources/pkg-config-*.tar.gz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/pkg-config-*.tar.gz -C /tmp/ \
    && mv /tmp/pkg-config-* /tmp/pkg-config \
    && pushd /tmp/pkg-config \
    && ./configure \
        --prefix=/usr \
        --with-internal-glib \
        --disable-host-tool \
        --docdir=/usr/share/doc/pkg-config-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/pkg-config

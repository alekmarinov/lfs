#!/bin/bash
set -e
echo "Building pkg config.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 28 MB"

# 8.27. Pkg-config
# The pkg-config package contains a tool for passing the include path and/or
# library paths to build tools during the configure and make phases of package installations.
VER=$(ls /sources/pkg-config-*.tar.gz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
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

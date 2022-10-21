#!/bin/bash
set -e
echo "Building procps-ng.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 19 MB"

# 8.72. Procps-ng
# The Procps-ng package contains programs for monitoring processes.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/procps-ng.html

VER=$(ls /sources/procps-ng-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/procps-ng-*.tar.xz -C /tmp/ \
    && mv /tmp/procps-ng-* /tmp/procps-ng \
    && pushd /tmp/procps-ng \
    && ./configure \
        --prefix=/usr \
        --docdir=/usr/share/doc/procps-ng-$VER \
        --disable-static \
        --disable-kill \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    popd \
    && rm -rf /tmp/procps-ng || true

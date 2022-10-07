#!/bin/bash
set -e
echo "Building procps-ng.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 19 MB"

# 8.72. Procps-ng
# The Procps-ng package contains programs for monitoring processes.
VER=$(ls /sources/man-db-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
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
    && rm -rf /tmp/procps-ng

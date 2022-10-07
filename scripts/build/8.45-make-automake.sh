#!/bin/bash
set -e
echo "Building Automake.."
echo "Approximate build time: less than 0.1 SBU (about 7.7 SBU with tests)"
echo "Required disk space: 116 MB"

# 8.45. Automake
VER=$(ls /sources/automake-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/automake-*.tar.xz -C /tmp/ \
    && mv /tmp/automake-* /tmp/automake \
    && pushd /tmp/automake \
    && ./configure --prefix=/usr --docdir=/usr/share/doc/automake-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make -j4 check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/automake

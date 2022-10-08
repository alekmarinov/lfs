#!/bin/bash
set -e
echo "Building IPRoute2.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 16 MB"

# 8.62. IPRoute2
# The IPRoute2 package contains programs for basic and advanced IPV4-based networking.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/iproute2.html

VER=$(ls /sources/iproute2-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/iproute2-*.tar.xz -C /tmp/ \
    && mv /tmp/iproute2-* /tmp/iproute2 \
    && pushd /tmp/iproute2 \
    && sed -i /ARPD/d Makefile \
    && rm -fv man/man8/arpd.8 \
    && make NETNS_RUN_DIR=/run/netns \
    && if [ $LFS_DOCS -eq 1 ]; then \
        mkdir -pv /usr/share/doc/iproute2-$VER; \
        cp -v COPYING README* /usr/share/doc/iproute2-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/iproute2

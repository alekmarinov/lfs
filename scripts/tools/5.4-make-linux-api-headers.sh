#!/bin/bash
set -e
echo "Building Linux API Headers.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 1.4 MB"

# 5.4. Linux API Headers
# Expose the kernel's API for use by Glibc.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter05/linux-headers.html

rm -rf /tmp/linux \
    && tar -xf $LFS_BASE/sources/linux-*.tar.xz -C /tmp/ \
    && mv /tmp/linux-* /tmp/linux \
    && pushd /tmp/linux \
    && make mrproper \
    && make headers \
    && find usr/include -type f ! -name '*.h' -delete \
    && mkdir -p $LFS_BASE/usr \
    && cp -rv usr/include $LFS_BASE/usr/ \
    && popd \
    && rm -rf /tmp/linux

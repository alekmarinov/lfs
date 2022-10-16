#!/bin/bash
set -e
echo "Building man pages.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 33 MB"

# 8.3. Man-pages
# The Man-pages package contains over 2,200 man pages.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/man-pages.html

tar -xf /sources/man-pages-*.tar.xz -C /tmp/ \
    && mv /tmp/man-pages-* /tmp/man-pages \
    && pushd /tmp/man-pages \
    && make prefix=/usr install \
    && popd \
    && rm -rf /tmp/man-pages

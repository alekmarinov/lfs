#!/bin/bash
set -e
echo "Building man pages.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 33 MB"

# 8.3. Man-pages
# The Man-pages package contains over 2,200 man pages.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/man-pages.html
#
# NOTE -R. man-pages 6.x refuses to build with make's built-in rules and
# stops with a message asking for it. GIT=false keeps it from consulting a
# repository it does not have. The crypt pages are removed because
# libxcrypt installs its own.

tar -xf /sources/man-pages-*.tar.xz -C /tmp/ \
    && mv /tmp/man-pages-* /tmp/man-pages \
    && pushd /tmp/man-pages \
    && rm -v man3/crypt* \
    && make -R GIT=false prefix=/usr install \
    && popd \
    && rm -rf /tmp/man-pages

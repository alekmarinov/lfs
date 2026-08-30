#!/bin/bash
set -e
echo "Building Autoconf.."
echo "Approximate build time: less than 0.1 SBU (about 6.7 SBU with tests)"
echo "Required disk space: 24 MB"

# 8.44. Autoconf
# The Autoconf package contains programs for producing shell scripts that can automatically configure source code.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/autoconf.html

tar -xf /sources/autoconf-*.tar.xz -C /tmp/ \
    && mv /tmp/autoconf-* /tmp/autoconf \
    && pushd /tmp/autoconf \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/autoconf

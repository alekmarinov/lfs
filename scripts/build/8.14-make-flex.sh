#!/bin/bash
set -e
echo "Building Flex.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 33 MB"

# 8.14. Flex
# The Flex package contains a utility for generating programs that recognize patterns in text.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/flex.html

VER=$(ls /sources/flex-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/flex-*.tar.gz -C /tmp/ \
    && mv /tmp/flex-* /tmp/flex \
    && pushd /tmp/flex \
    && ./configure --prefix=/usr \
        --docdir=/usr/share/doc/flex-$VER \
        --disable-static \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && ln -sv flex /usr/bin/lex \
    && popd \
    && rm -rf /tmp/flex

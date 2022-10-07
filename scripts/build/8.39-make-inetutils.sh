#!/bin/bash
set -e
echo "Building Inetutils.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 31 MB"

# 8.39. Inetutils
# The Inetutils package contains programs for basic networking.
tar -xf /sources/inetutils-*.tar.xz -C /tmp/ \
    && mv /tmp/inetutils-* /tmp/inetutils \
    && pushd /tmp/inetutils \
    && ./configure \
        --prefix=/usr \
        --bindir=/usr/bin \
        --localstatedir=/var \
        --disable-logger \
        --disable-whois \
        --disable-rcp \
        --disable-rexec \
        --disable-rlogin \
        --disable-rsh \
        --disable-servers \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && mv -v /usr/{,s}bin/ifconfig \
    && popd \
    && rm -rf /tmp/inetutils

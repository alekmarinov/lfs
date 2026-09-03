#!/bin/bash
# PACKAGE:  inetutils
# SOURCE:   inetutils-*.tar.xz
# RELEASE:  1
# CLASS:    core
set -e
echo "Building Inetutils.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 31 MB"

# 8.39. Inetutils
# The Inetutils package contains programs for basic networking.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/inetutils.html
#
# NOTE the sed is the book's fix, turning '#ifdef HAVE_TERMCAP_TGETENT' into
# '#if 1' so telnet declares tgetent(). Left out, the call is an implicit
# declaration, which GCC 15 rejects outright rather than warning about.

tar -xf /sources/inetutils-*.tar.xz -C /tmp/ \
    && mv /tmp/inetutils-* /tmp/inetutils \
    && pushd /tmp/inetutils \
    && sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c \
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

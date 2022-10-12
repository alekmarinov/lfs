#!/bin/bash
set -e
echo "Building BLFS-efivar.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 18 MB"

# 5. efivar
# The efivar package provides tools and libraries to manipulate EFI variables.
# https://www.linuxfromscratch.org/blfs/view/svn/postlfs/efivar.html

tar -xf /sources/efivar-*.tar.bz2 -C /tmp/ \
    && mv /tmp/efivar-* /tmp/efivar \
    && pushd /tmp/efivar \
    && sed '/prep :/a\\ttouch prep' -i src/Makefile \
    && sed '/sys\/mount\.h/d' -i src/util.h \
    && sed '/unistd\.h/a#include <sys/mount.h>' -i src/gpt.c src/linux.c \
    && [ $(getconf LONG_BIT) = 64 ] || patch -Np1 -i /sources/efivar-38-i686-1.patch \
    && make \
    && make install LIBDIR=/usr/lib \
    && popd \
    && rm -rf /tmp/efivar

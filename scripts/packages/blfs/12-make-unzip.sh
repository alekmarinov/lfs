#!/bin/bash
# PACKAGE:  unzip
# SOURCE:   unzip60.tar.gz
# VERSION:  6.0
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-unzip.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 9 MB"

# 12. unzip
# The UnZip package contains ZIP extraction utilities.
# https://www.linuxfromscratch.org/blfs/view/stable/general/unzip.html
#
# NOTE the compiler settings. unzip redeclares gmtime() and localtime() with
# empty parentheses, which C23 reads as taking no arguments, so they conflict
# with time.h - hence -std=gnu17. The -Wno-error pair is for the 'generic'
# target's own feature probes, which are old-style programs: GCC 14 turned
# those diagnostics into errors, so the probes failed and unzip concluded it
# had no dirent.h, falling back to 'typedef FILE DIR'.

VER=$(ls /sources/unzip60.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/unzip60.tar.gz -C /tmp/ \
    && pushd /tmp/unzip60 \
    && patch -Np1 -i /sources/unzip-6.0-consolidated_fixes-1.patch \
    && make -f unix/Makefile CC='gcc -std=gnu17 -Wno-error=implicit-int -Wno-error=implicit-function-declaration' generic \
    && make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install \
    && popd \
    && rm -rf /tmp/unzip60

#!/bin/bash
set -e
echo "Building BLFS-bootscripts.."

# 2. blfs-bootscripts
# The BLFS Bootscripts package contains the init scripts that are used throughout the book.
# It is assumed that you will be using the BLFS Bootscripts package in conjunction with a
# compatible LFS-Bootscripts package. 
# https://www.linuxfromscratch.org/blfs/view/stable/introduction/bootscripts.html

tar -xf /sources/blfs-bootscripts-*.tar.xz -C /tmp/ \
    && mv /tmp/blfs-bootscripts-* /tmp/blfs-bootscripts


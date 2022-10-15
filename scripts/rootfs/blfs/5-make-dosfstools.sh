#!/bin/bash
set -e
echo "Building BLFS-dosfstools.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 3.5 MB"

# 5. dosfstools
# The dosfstools package contains various utilities for use with the FAT family of file systems. 
# https://www.linuxfromscratch.org/blfs/view/svn/postlfs/dosfstools.html

# Kernel config:
# ------------------------------------------------------------------------
# File systems --->
#   <DOS/FAT/EXFAT/NT Filesystems --->
#     <*/M> MSDOS fs support             [CONFIG_MSDOS_FS]
#     <*/M> VFAT (Windows-95) fs support [CONFIG_VFAT_FS]

VER=$(ls /sources/dosfstools-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/dosfstools-*.tar.gz -C /tmp/ \
    && mv /tmp/dosfstools-* /tmp/dosfstools \
    && pushd /tmp/dosfstools \
    && ./configure \
        --prefix=/usr \
        --enable-compat-symlinks \
        --mandir=/usr/share/man \
        --docdir=/usr/share/doc/dosfstools-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/dosfstools

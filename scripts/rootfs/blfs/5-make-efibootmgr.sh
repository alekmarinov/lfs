#!/bin/bash
set -e
echo "Building BLFS-efibootmgr.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 1.1 MB"

# 5. efibootmgr
# The efibootmgr package provides tools and libraries to manipulate EFI variables.
# https://www.linuxfromscratch.org/blfs/view/svn/postlfs/efibootmgr.html

tar -xf /sources/efibootmgr-*.tar.gz -C /tmp/ \
    && mv /tmp/efibootmgr-* /tmp/efibootmgr \
    && pushd /tmp/efibootmgr \
    && make EFIDIR=LFS EFI_LOADER=grubx64.efi \
    && make install EFIDIR=LFS \
    && popd \
    && rm -rf /tmp/efibootmgr

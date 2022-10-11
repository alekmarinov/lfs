#!/bin/bash
set -e
echo "Building BLFS-mdadm.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 5 MB"

# 5. mdadm
# The mdadm package contains administration tools for software RAID.
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/mdadm.html

# Kernel config:
# ------------------------------------------------------------------------
# Device Drivers --->
#   [*] Multiple devices driver support (RAID and LVM) ---> [CONFIG_MD]
#     <*> RAID support                                      [CONFIG_BLK_DEV_MD]
#     [*]   Autodetect RAID arrays during kernel boot       [CONFIG_MD_AUTODETECT]
#     <*/M>  Linear (append) mode                           [CONFIG_MD_LINEAR]
#     <*/M>  RAID-0 (striping) mode                         [CONFIG_MD_RAID0]
#     <*/M>  RAID-1 (mirroring) mode                        [CONFIG_MD_RAID1]
#     <*/M>  RAID-10 (mirrored striping) mode               [CONFIG_MD_RAID10]
#     <*/M>  RAID-4/RAID-5/RAID-6 mode                      [CONFIG_MD_RAID456]

tar -xf /sources/mdadm-*.tar.xz -C /tmp/ \
    && mv /tmp/mdadm-* /tmp/mdadm \
    && pushd /tmp/mdadm \
    && make \
    && make BINDIR=/usr/sbin install \
    && popd \
    && rm -rf /tmp/mdadm

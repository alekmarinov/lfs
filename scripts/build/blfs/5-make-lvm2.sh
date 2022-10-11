#!/bin/bash
set -e
echo "Building BLFS-lvm2.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 2.5 MB"

# 5. lvm2
# The LVM2 package is a set of tools that manage logical partitions.
# It allows spanning of file systems across multiple physical disks and disk 
# partitions and provides for dynamic growing or shrinking of logical partitions,
# mirroring and low storage footprint snapshots.
# requires: libaio
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/lvm2.html

# Kernel config:
# ------------------------------------------------------------------------
# Device Drivers --->
#   [*] Multiple devices driver support (RAID and LVM) ---> [CONFIG_MD]
#     <*/M>   Device mapper support                         [CONFIG_BLK_DEV_DM]
#     <*/M>   Crypt target support                          [CONFIG_DM_CRYPT]
#     <*/M>   Snapshot target                               [CONFIG_DM_SNAPSHOT]
#     <*/M>   Thin provisioning target                      [CONFIG_DM_THIN_PROVISIONING]
#     <*/M>   Cache target (EXPERIMENTAL)                   [CONFIG_DM_CACHE]
#     <*/M>   Mirror target                                 [CONFIG_DM_MIRROR]
#     <*/M>   Zero target                                   [CONFIG_DM_ZERO]
#     <*/M>   I/O delaying target                           [CONFIG_DM_DELAY]
#   [*] Block devices --->
#     <*/M>   RAM block device support                      [CONFIG_BLK_DEV_RAM]
# Kernel hacking --->
#   Generic Kernel Debugging Instruments --->
#     [*] Magic SysRq key                                   [CONFIG_MAGIC_SYSRQ]

tar -xf /sources/LVM2.*.tgz -C /tmp/ \
    && mv /tmp/LVM2.* /tmp/LVM2 \
    && pushd /tmp/LVM2 \
    && PATH+=:/usr/sbin \
    && ./configure \
        --prefix=/usr \
        --enable-cmdlib \
        --enable-pkgconfig \
        --enable-udev_sync \
        --with-thin-check= \
        --with-thin-dump= \
        --with-thin-repair= \
        --with-thin-restore= \
        --with-cache-check= \
        --with-cache-dump= \
        --with-cache-repair= \
        --with-cache-restore= \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then \
        make -C tools install_tools_dynamic; \
        make -C udev install; \
        make -C libdm install; \
        dmesg -D; \
        LC_ALL=en_US.UTF-8 make S=lvconvert-repair-replace check_local; \
        dmesg -E; \
    fi \
    && make install \
    && rm /usr/lib/udev/rules.d/69-dm-lvm.rules \
    && popd \
    && rm -rf /tmp/LVM2

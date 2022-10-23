#!/bin/bash
echo "Mounting Virtual Kernel File Systems.."

# 7.3. Preparing Virtual Kernel File Systems
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/kernfs.html

echo "Mounting vkfs $LFS_BASE/{dev,proc,sys,run}"
mkdir -pv $LFS_BASE/{dev,proc,sys,run}

# mount and populate /dev
mount -v --bind /dev $LFS_BASE/dev

# mount Virtual Kernel File Systems
mount -v --bind /dev/pts $LFS_BASE/dev/pts
mount -vt proc proc $LFS_BASE/proc
mount -vt sysfs sysfs $LFS_BASE/sys
mount -vt tmpfs tmpfs $LFS_BASE/run

if [ -h $LFS_BASE/dev/shm ]; then
    mkdir -pv $LFS_BASE/$(readlink $LFS_BASE/dev/shm)
fi

#!/bin/bash
echo "Mounting Virtual Kernel File Systems.."
__NAME__=$(basename "$0")

# 7.3. Preparing Virtual Kernel File Systems
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/kernfs.html

if [ "$LFS" == "" ]; then
    echo "$__NAME__: $LFS is not defined"
    exit 1
fi

echo "Mounting vkfs $LFS/{dev,proc,sys,run}"
mkdir -pv $LFS/{dev,proc,sys,run}

# mount and populate /dev
mount -v --bind /dev $LFS/dev

# mount Virtual Kernel File Systems
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
    mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

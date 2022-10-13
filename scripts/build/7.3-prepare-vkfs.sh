#!/bin/bash
echo "Preparing Virtual Kernel File Systems.."

# 7.2. Changing Ownership
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/changingowner.html

chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac
# prevent "bad interpreter: Text file busy"
sync

# 7.3. Preparing Virtual Kernel File Systems
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/kernfs.html

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

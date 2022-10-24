#!/bin/bash
set -e
echo "Unmounting Virtual Kernel File Systems.."
__NAME__=$(basename "$0")

if [ "$LFS" == "" ]; then
    echo "$__NAME__: $LFS is not defined"
    exit 1
fi

# unmount VFS
umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys

#!/bin/bash
set -e
echo "Unmounting Virtual Kernel File Systems.."

# unmount VFS
umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys

# unmount LFS
umount -v $LFS

#!/bin/bash
set -e
echo "Unmounting Virtual Kernel File Systems.."

# unmount VFS
umount -v $LFS_BASE/dev/pts
umount -v $LFS_BASE/dev
umount -v $LFS_BASE/run
umount -v $LFS_BASE/proc
umount -v $LFS_BASE/sys

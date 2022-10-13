#!/bin/bash
set -e
echo "Running build rootfs..."

# mount vkfs
sh $LFS/scripts/rootfs/7.3-mount-vkfs.sh

# enter and continue in chroot environment
/usr/sbin/chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    LFS="$LFS" LC_ALL="$LC_ALL" \
    LFS_TGT="$LFS_TGT" MAKEFLAGS="$MAKEFLAGS" \
    LFS_TEST="$LFS_TEST" LFS_DOCS="$LFS_DOCS" \
    JOB_COUNT="$JOB_COUNT" \
    /bin/bash --login +h -c "sh /scripts/rootfs/as-chroot.sh"

# unmount vkfs
sh $LFS/scripts/rootfs/11-unmount-vkfs.sh

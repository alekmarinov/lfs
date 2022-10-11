#!/bin/bash
set -e
echo "Running build.."

# prepartion
sh /tools/build/7.3-prepare-vkfs.sh

# enter and continue in chroot environment with tools
/usr/sbin/chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    LFS="$LFS" LC_ALL="$LC_ALL" \
    LFS_TGT="$LFS_TGT" MAKEFLAGS="$MAKEFLAGS" \
    LFS_TEST="$LFS_TEST" LFS_DOCS="$LFS_DOCS" \
    JOB_COUNT="$JOB_COUNT" \
    /bin/bash --login +h -c "sh /tools/as-chroot.sh"

# cleanup
sh /tools/build/11.x-cleanup.sh

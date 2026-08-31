#!/bin/bash
set +e
echo "Unmounting Virtual Kernel File Systems.."
__NAME__=$(basename "$0")

if [ "$LFS" == "" ]; then
    echo "$__NAME__: LFS is not defined"
    exit 1
fi

# unmount VFS
umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys

# Best effort, and it has to say so in its exit status too. 'set +e' above
# already says the intent - a file system which is not mounted is not an error
# here - but without this the script still exits with the status of the last
# umount. build-package.sh calls this with its ERR trap armed, so one already
# unmounted /sys discards a package that built perfectly well: the compile
# succeeds, the cleanup returns 1, and the trap fires before the tar is ever
# written. That is how a 20 minute kernel build is lost to a umount.
exit 0

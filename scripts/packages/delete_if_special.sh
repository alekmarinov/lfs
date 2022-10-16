#!/bin/bash
# Multiple files to delete from $LFS_BASE if of type inode/chardevice
# When a package attempts to delete a file or directory from overlay/lfs (mountpoint) directory
# in the upperdir overlay/package will appear zero sized file of type inode/chardevice
# This is a mark that this file must be deleted from base.
# This script is a helper of build.sh.

while [[ $# -gt 0 ]]; do
    [[ "$(file -ib $1)" = "inode/chardevice;"* ]] && rm -rf "$1" "$LFS_BASE/$1"
    shift
done

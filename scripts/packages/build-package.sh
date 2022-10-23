#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TMP="tmp"

o_force=0
script_path=""
while [[ $# -gt 0 ]]; do
    case $1 in
    -f|--force)
        o_force=1
        shift
        ;;
    -*|--*)
        echo "build.sh: Unknown option $1"
        exit 1
        ;;
    *)
        if [[ "$script_path" != "" ]]; then
            echo "build.sh: only one positional argument expected - script_path"
            exit 1
        fi
        script_path="$1"
        shift
        ;;
    esac
done
if [ "$script_path" == "" ]; then
    echo "Missing argument: script_path"
    exit 1
fi

rm -rf "$LFS_PACKAGE"/*
mount -t overlay overlay \
    "-olowerdir=$LFS_BASE,upperdir=$LFS_PACKAGE,workdir=overlay/work" \
    "$LFS"

script_name=$(basename -- "$script_path")
# flag file on the host
flag_file="$TMP/${script_name%.*}.ready"
# log file on the chroot system
log_file="/tmp/${script_name%.*}.log"
package_name="$TMP/${script_name%.*}.tar.gz"
if [[ ! -f "$flag_file" || $o_force -eq 1 ]]; then
    if [ ! -f "$LFS/$script_path" ]; then
        echo -ne "\r\nbuild.sh: Can't find script $LFS/$script_path"
        exit 1
    fi
    # mount vkfs before chroot
    $LFS/scripts/packages/7.3-mount-vkfs.sh > /dev/null 2>&1
    /usr/sbin/chroot "$LFS" /usr/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PS1='(lfs chroot) \u:\w\$ ' \
        PATH=/usr/bin:/usr/sbin \
        LFS="$LFS" LC_ALL="$LC_ALL" \
        LFS_TGT="$LFS_TGT" MAKEFLAGS="$MAKEFLAGS" \
        LFS_TEST="$LFS_TEST" LFS_DOCS="$LFS_DOCS" \
        JOB_COUNT="$JOB_COUNT" \
        /bin/bash --login +h -c "sh -c '$script_path > $log_file 2>&1'"
    status=$?
    $LFS/scripts/packages/11-unmount-vkfs.sh > /dev/null 2>&1
else
    echo "skipped $script_path"
    exit 0
fi
if [ $status -eq 0 ]; then
    echo -ne "\rpassed"; echo
    # Archive package
    tar cfz "$package_name" -C "$LFS_PACKAGE" .
    # Mark this build has been passed
    touch "$flag_file"
    # Copy all but delete special files/dirs from destination
    "$SCRIPT_DIR/packages/copy-or-del.sh" "$LFS_PACKAGE" "$LFS_BASE"
    # Clean $LFS_PACKAGE folder
    rm -rf "$LFS_PACKAGE"/*
else
    echo -ne "\rfailed"; echo
    # The log_file should remain in $LFS_PACKAGE/tmp
    tail "$log_file"
    echo
    # Exit with failure
    exit 1
fi

sync
umount overlay/lfs

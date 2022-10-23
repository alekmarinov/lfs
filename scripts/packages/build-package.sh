#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
__NAME__=$(basename "$0")
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
        echo ": Unknown option $1"
        exit 1
        ;;
    *)
        if [[ "$script_path" != "" ]]; then
            echo "$__NAME__: only one positional argument expected - script_path"
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

__NAME__=$(basename -- "$script_path")
# flag file on the host
flag_file="$TMP/${__NAME__%.*}.ready"
# log file on the chroot system
log_file="/tmp/${__NAME__%.*}.log"
package_name="$TMP/${__NAME__%.*}.tar.gz"
if [[ ! -f "$flag_file" || $o_force -eq 1 ]]; then
    if [ ! -f "$LFS/$script_path" ]; then
        echo -ne "\r\n$__NAME__: Can't find script $LFS/$script_path"
        exit 1
    fi
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
else
    echo "$__NAME__: skipped $script_path"
    exit 0
fi
if [ $status -eq 0 ]; then
    echo -ne "\rpassed"; echo
    # Archive package
    tar cfz "$package_name" -C "$LFS_PACKAGE" .
    # Mark this build has been passed
    touch "$flag_file"
    # Copy all but delete special files/dirs from destination
    "$SCRIPT_DIR/copy-or-del.sh" "$LFS_PACKAGE" "$LFS_BASE"
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

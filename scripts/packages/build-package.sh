#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
__NAME__=$(basename "$0")

for var in LFS LFS_BASE LFS_PACKAGE LFS_PACKAGES; do
    if [ "${!var}" == "" ]; then
        echo "$__NAME__: $var is not defined"
        exit 1
    fi
done

error_trap() {
    set +e
    echo -e "\n$__NAME__: Error occurred at line $1"
    sync
    $SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1
    umount $LFS
    exit 1
}

trap 'error_trap $LINENO' ERR

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

script_name=$(basename -- "$script_path")
# flag file on the host
flag_file="tmp/${script_name%.*}.ready"
# log file on the chroot system
log_file="${script_name%.*}.log"
echo -ne "...... $script_path -> $log_file"
if [[ ! -f "$flag_file" || $o_force -eq 1 ]]; then
    # mount overlay to isolate the installed files in $LFS_PACKAGE
    sync
    mount -t overlay overlay \
        "-olowerdir=$LFS_BASE,upperdir=$LFS_PACKAGE,workdir=overlay/work" \
        "$LFS"

    script_path_local=$(echo $LFS/$script_path | sed "s/\/\//\//g")
    if [ ! -f "$script_path_local" ]; then
        echo -ne "\r\n$__NAME__: Can't find script $script_path_local"
        exit 1
    fi

    # mount vkfs to the chroot directory
    $SCRIPT_DIR/7.3-mount-vkfs.sh > /dev/null 2>&1
    /usr/sbin/chroot "$LFS" /usr/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PS1='(lfs chroot) \u:\w\$ ' \
        PATH=/usr/bin:/usr/sbin \
        $(cat .env | xargs) \
        /bin/bash --login +h -c "sh -c '$script_path > /tmp/$log_file 2>&1'"
    status=$?
    sync
    $SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1
    sync
    umount $LFS
else
    echo -ne "\rskip   $script_path"; echo
    exit 0
fi
if [ $status -eq 0 ]; then
    echo -ne "\rpassed"; echo
    # Archive package
    package_name="$LFS_PACKAGES/${script_name%.*}.tar.gz"
    tar cfz "$package_name" -C "$LFS_PACKAGE" .
    # Copy all but delete special files/dirs from destination
    "$SCRIPT_DIR/copy-or-del.sh" "$LFS_PACKAGE" "$LFS_BASE"
    # Clean package directory
    rm -rf "$LFS_PACKAGE"/*
    # Mark this build has been passed as the same package successful install is not guaranteed
    touch "$flag_file"
else
    echo -ne "\rfailed"; echo
    # The log_file should remain in $LFS_PACKAGE/tmp
    tail "$LFS/tmp/$log_file"
    echo
    # Exit with failure
    exit 1
fi

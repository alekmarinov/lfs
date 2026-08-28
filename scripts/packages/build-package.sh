#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
__NAME__=$(basename "$0")

for var in LFS LFS_BASE LFS_PACKAGE LFS_PACKAGES; do
    if [ "${!var}" == "" ]; then
        echo "$__NAME__: $var is not defined"
        exit 1
    fi
done

# The build is finished by the time $LFS is unmounted, and the package is made
# from the upper layer afterwards. A busy mount point therefore has to be
# retried rather than allowed to fail: it is enough for a shell to sit with its
# working directory inside the overlay - watching the build log lives there -
# and a completed build is thrown away for no reason. The last resort is a lazy
# unmount, which detaches the tree now and releases it when the last user goes.
unmount_lfs() {
    local i out
    for i in 1 2 3 4 5; do
        if out=$(umount "$LFS" 2>&1); then
            return 0
        fi
        echo "$__NAME__: $LFS is busy, retrying ($i/5).."
        sleep 2
    done
    echo "$__NAME__: could not unmount $LFS: $out"
    echo "$__NAME__: held by:"
    fuser -vm "$LFS" 2>&1 | sed 's/^/    /' || true
    echo "$__NAME__: detaching it lazily so the finished build is not lost"
    umount -l "$LFS"
}

error_trap() {
    set +e
    # $2 is the command bash was running when the trap fired. A line number on
    # its own says where to look but not what went wrong, and the real error is
    # usually already scrolled past by the time this prints.
    echo -e "\n$__NAME__: failed at line $1${2:+: $2}"
    sync
    $SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1
    umount $LFS
    exit 1
}

trap 'error_trap $LINENO "$BASH_COMMAND"' ERR

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
    # Clean package directory
    rm -rf "$LFS_PACKAGE"/*
    mount -t overlay overlay \
        "-olowerdir=$LFS_BASE,upperdir=$LFS_PACKAGE,workdir=overlay/work" \
        "$LFS"

    script_path_local=$(echo $LFS/$script_path | sed "s/\/\//\//g")
    if [ ! -f "$script_path_local" ]; then
        echo -ne "\r\n$__NAME__: Can't find script $script_path_local"
        exit 1
    fi

    # mount vkfs to the chroot directory
    $SCRIPT_DIR/7.3-mount-vkfs.sh > /dev/null
    # The build failing inside the chroot is reported below, with the tail of
    # its log. Without disarming the trap the chroot returning non zero fires
    # it first, which unmounts and leaves only a line number behind.
    trap - ERR
    /usr/sbin/chroot "$LFS" /usr/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PS1='(lfs chroot) \u:\w\$ ' \
        PATH=/usr/bin:/usr/sbin \
        $(cat .env | xargs) \
        /bin/bash --login +h -c "sh -c '$script_path > /tmp/$log_file 2>&1'"
    status=$?
    trap 'error_trap $LINENO "$BASH_COMMAND"' ERR
    sync
    $SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1
    sync
    unmount_lfs
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
    # $LFS is unmounted by now, the log survives in the package layer
    tail -n 25 "$LFS_PACKAGE/tmp/$log_file"
    echo
    # Exit with failure
    exit 1
fi

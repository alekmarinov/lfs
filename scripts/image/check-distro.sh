#!/bin/bash
# Smoke checks the assembled rootfs without booting it.
#
# Every program is resolved against the libraries of the rootfs itself, which
# catches the packages a distro forgot to list - the failure a boot test can
# only report for the programs it happens to run.
set -e

ROOTFS_DIR="rootfs"

[ -d "$ROOTFS_DIR" ] || { echo "Directory '$ROOTFS_DIR' is missing, run 'make distro DISTRO=...' first"; exit 1; }

PRETTY_NAME=$(sed -n 's/^PRETTY_NAME="\(.*\)"/\1/p' "$ROOTFS_DIR/etc/os-release" 2>/dev/null)
echo "Checking '${PRETTY_NAME:-unknown distro}' in '$ROOTFS_DIR'"

# the pieces without which nothing runs at all
echo
echo "Layout:"
status=0
for path in bin sbin lib lib64/ld-linux-x86-64.so.2 usr/bin/sh usr/bin/bash usr/sbin/init etc/os-release; do
    if sudo test -e "$ROOTFS_DIR/$path"; then
        echo "    ok      /$path"
    else
        echo "    MISSING /$path"
        status=1
    fi
done

# a whiteout which survived the assembly would be read as a corrupt file
whiteouts=$(sudo find "$ROOTFS_DIR" -type c 2>/dev/null | wc -l)
echo
if [ "$whiteouts" -eq 0 ]; then
    echo "Device nodes: none left over"
else
    echo "Device nodes: $whiteouts unexpected, deleted files were not applied"
    sudo find "$ROOTFS_DIR" -type c 2>/dev/null | sed "s|^$ROOTFS_DIR|    |"
    status=1
fi

# resolve every program against the libraries of the rootfs
echo
echo "Shared libraries:"
report=$(sudo chroot "$ROOTFS_DIR" /usr/bin/bash -c '
for f in /usr/bin/* /usr/sbin/*; do
    [ -f "$f" ] || continue
    missing=""
    while read -r line; do
        case "$line" in
            *"not found"*) missing="$missing ${line%% *}" ;;
        esac
    done < <(ldd "$f" 2>/dev/null)
    [ -n "$missing" ] && echo "    ${f}:${missing}"
done
true' 2>/dev/null)

if [ -z "$report" ]; then
    echo "    ok      every program resolves"
else
    echo "$report"
    echo
    echo "    $(echo "$report" | wc -l) programs can not run, the distro is missing the packages providing those libraries"
    status=1
fi

echo
if [ $status -eq 0 ]; then
    echo "'$PRETTY_NAME' passed"
else
    echo "'$PRETTY_NAME' has the problems reported above"
fi
exit $status

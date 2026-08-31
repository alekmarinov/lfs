#!/bin/bash
# Smoke checks the assembled rootfs without booting it.
#
# Every program and shared object is resolved against the libraries of the
# rootfs itself, which catches the packages a distro forgot to list - the
# failure a boot test can only report for the programs it happens to run.
#
# A distro may accept a set of unresolved files in distros/<distro>/check.ignore,
# for the auxiliary tools its packages install but it does not need. Anything
# unresolved which is not listed there fails the check.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )

# Same argument as build-distro.sh, and the same rootfs: a distro's output has
# one home and every script derives it the same way.
OUT=$("$BASE_DIR/scripts/resolve-distro.sh" -o "$1")
ROOTFS_DIR="$OUT/rootfs"

[ -d "$ROOTFS_DIR" ] || { echo "Directory '$ROOTFS_DIR' is missing, run 'make distro DISTRO=...' first"; exit 1; }

PRETTY_NAME=$(sed -n 's/^PRETTY_NAME="\(.*\)"/\1/p' "$ROOTFS_DIR/etc/os-release" 2>/dev/null)
DISTRO=$(sed -n 's/^DISTRO=//p' "$ROOTFS_DIR/etc/lfs-distro" 2>/dev/null)
# from the rootfs, not from distros/$DISTRO - a distro may live anywhere now,
# and build-distro.sh copies its own files in beside the rootfs it produced.
IGNORE_FILE="$ROOTFS_DIR/etc/lfs-distro.d/check.ignore"

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

# Resolve every program and shared object against the libraries of the rootfs.
#
# NOTE the loop must not use a process substitution: there is no /dev/fd inside
# the chroot, the redirection fails and every file is then reported as fine.
echo
echo "Shared libraries:"

# the scan runs bash inside the rootfs, so a rootfs whose bash can not run at
# all would report nothing and look clean
if ! sudo chroot "$ROOTFS_DIR" /usr/bin/bash -c 'exit 0' 2>/dev/null; then
    echo "    FAILED  /usr/bin/bash can not run inside the rootfs, it can not be checked"
    sudo chroot "$ROOTFS_DIR" /usr/bin/bash -c 'exit 0' 2>&1 | sed 's/^/    /' || true
    echo
    echo "'$PRETTY_NAME' has the problems reported above"
    exit 1
fi

report=$(sudo chroot "$ROOTFS_DIR" /usr/bin/bash -c '
check() {
    local f="$1" missing
    missing=$(ldd "$f" 2>/dev/null | grep "not found" \
        | sed "s/[[:space:]]*\([^ ]*\).*/\1/" | sort -u | tr "\n" " ")
    [ -n "$missing" ] && echo "${f}|${missing}"
    return 0
}
# the programs, and the shared objects they load at runtime - a plugin of a
# program, like the sudoers policy of sudo, fails just as hard as the program
for f in /usr/bin/* /usr/sbin/* /usr/libexec/*; do
    [ -f "$f" ] && check "$f"
done
find /usr/libexec -type f 2>/dev/null | while read -r f; do
    check "$f"
done
find /usr/lib -type f -name "*.so*" 2>/dev/null | while read -r f; do
    check "$f"
done
true' 2>/dev/null)

# split the findings into the ones the distro accepts and the ones it does not
accepted=""
unexpected=""
if [ -n "$report" ]; then
    while IFS='|' read -r file libs; do
        [ -z "$file" ] && continue
        # An entry is matched as a shell pattern, so a plain path still means
        # itself and a library can be accepted without naming its soname.
        # Pinning the version - libgmpxx.so.4.6.1 - means the entry stops
        # matching the day the package is updated, and the distro then fails
        # a check for a reason that has nothing to do with what changed.
        ignored=no
        if [ -f "$IGNORE_FILE" ]; then
            while read -r pattern; do
                [ -z "$pattern" ] && continue
                case "$file" in $pattern) ignored=yes; break ;; esac
            done < <(sed 's/#.*//' "$IGNORE_FILE" | tr -d '[:blank:]')
        fi
        if [ "$ignored" = yes ]; then
            accepted="$accepted    $file: $libs"$'\n'
        else
            unexpected="$unexpected    $file: $libs"$'\n'
        fi
    done <<< "$report"
fi

if [ -z "$unexpected" ] && [ -z "$accepted" ]; then
    echo "    ok      every program and library resolves"
else
    if [ -n "$unexpected" ]; then
        printf '%s' "$unexpected"
        echo
        echo "    $(printf '%s' "$unexpected" | grep -c .) unresolved, the distro is missing the packages providing those libraries"
        status=1
    else
        echo "    ok      nothing unresolved beyond what the distro accepts"
    fi
    if [ -n "$accepted" ]; then
        echo
        echo "Accepted by $(realpath --relative-to="$BASE_DIR" "$IGNORE_FILE" 2>/dev/null || echo "$IGNORE_FILE"):"
        printf '%s' "$accepted"
    fi
fi

echo
if [ $status -eq 0 ]; then
    echo "'$PRETTY_NAME' passed"
else
    echo "'$PRETTY_NAME' has the problems reported above"
fi
exit $status

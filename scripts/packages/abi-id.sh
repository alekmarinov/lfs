#!/bin/bash
# The fingerprint of the core these packages were compiled against.
#
#   abi-id.sh            print the id
#   abi-id.sh -v         print it, and what went into it
#
# Every package in the cache is compiled against one exact core: this glibc,
# this gcc, this openssl. A package is only installable on a system built from
# a compatible one, and nothing in a package says so - a binary linked against
# libssl.so.3 installs perfectly happily onto a system carrying libssl.so.1.1
# and fails when it is first run, which may be on a machine nobody is looking
# at.
#
# So the core is hashed and the result travels with everything: stamped into
# /etc/os-release of an assembled distro, and used as the channel a repository
# is published under. An 'lpkg' refusing a channel whose id is not its own is
# the check that cannot be forgotten, because it needs nobody to remember it.
#
# What goes into the hash is the identity - name, version and release - of the
# core packages which provide a shared library, together with the
# architecture. Not the file contents: two builds of the same sources are the
# same ABI even when the bytes differ, and hashing the bytes would invalidate
# the repository every time anything was rebuilt.
#
# It follows that bumping '# RELEASE:' on glibc or openssl changes the ABI id,
# which is correct and is the point: a rebuilt glibc is a new world for
# everything compiled against it.
#
# Only the packages providing a library, because those are the only ones a
# binary can be incompatible with. Half the core provides none - sed, tar,
# grep, the bootscripts, the configure-* steps, lpkg itself - and including
# them made the id change for reasons that cannot break a binary. That is not
# a small matter of taste: with lpkg in the core, every update to the package
# manager would have changed the ABI, made every published channel
# unreachable, and required a reimage to fix a shell script.
#
# The trade is stated plainly: a new sed in the core no longer invalidates the
# channel. It should not - nothing is compiled against sed.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
INDEX="$PACKAGES_DIR/.meta-index"
CORE_LIST="distros/core/packages.list"
ARCH="${PKG_ARCH:-x86_64}"

verbose=0
[ "${1:-}" = "-v" ] && verbose=1

[ -f "$CORE_LIST" ] || { echo "No $CORE_LIST" >&2; exit 1; }
[ -d "$INDEX" ] || {
    echo "No metadata index at '$INDEX' - run 'make packages-meta' first" >&2
    exit 1
}

missing=0
skipped=0
ids=()
while read -r pkg; do
    case "$pkg" in ''|\#*) continue ;; esac
    name=${pkg%.tar.gz}
    info="$INDEX/$name/PKGINFO"
    if [ ! -f "$info" ]; then
        echo "$name: no PKGINFO in the index" >&2
        missing=$((missing + 1))
        continue
    fi
    # read rather than sourced: PKGINFO is data
    # no shared library, no way for a binary to be incompatible with it
    if [ ! -s "$INDEX/$name/provides" ]; then
        skipped=$((skipped + 1))
        continue
    fi
    n=$(sed -n 's/^name=//p'    "$info")
    v=$(sed -n 's/^version=//p' "$info")
    r=$(sed -n 's/^release=//p' "$info")
    ids+=("$n-$v-$r")
done < "$CORE_LIST"

if [ "$missing" -gt 0 ]; then
    echo "$missing core package(s) are not in the index; the id would not describe the core" >&2
    exit 1
fi

# Sorted, so the id depends on what the core is and not on the order somebody
# happened to list it in.
mapfile -t sorted < <(printf '%s\n' "${ids[@]}" | sort)

# 12 hex characters. Long enough that two different cores will not collide in
# any repository anyone will host, short enough to read out of os-release and
# to sit in a URL path.
id=$(printf '%s\n' "$ARCH" "${sorted[@]}" | sha256sum | cut -c1-12)

if [ "$verbose" = 1 ]; then
    echo "arch: $ARCH"
    echo "$skipped core package(s) provide no library and are not part of the ABI"
    echo "${#sorted[@]} core packages define it:"
    printf '  %s\n' "${sorted[@]}"
    echo
fi
echo "$id"

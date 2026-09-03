#!/bin/bash
# What is in the build base and in no package.
#
#   base-gap.sh [--all]
#
# The build base is the tree 'make packages' builds into: chapters 5 and 6 put
# the temporary toolchain there directly, and every package built afterwards is
# unpacked over it. So the base is not the union of the packages - it also
# holds whatever the tools build installed without a recipe, and those files
# belong to nothing.
#
# It does not matter while a distro is assembled, because build-distro.sh makes
# the few that matter by hand. It matters a great deal for anything which
# reconstructs a root out of packages alone:
#
#   lpkg --root /mnt/new install ...     the sanctioned way to update core
#   lpkg build                           the lower layer of its build overlay
#
# Both produce a tree which is missing them, and the way that shows up is
# obscure: no /usr/bin/sh, so every configure script stops at "bad
# interpreter"; no gnu/stubs-64.h, so every compile fails in the first header;
# no /lib64/ld-linux-x86-64.so.2, so nothing dynamically linked runs at all.
# Each of those was found by hitting it.
#
# /tools is excluded by default - it is the temporary cross-toolchain, which is
# correctly in no package and is thrown away. --all keeps it.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
BASE="${LFS_BASE:-overlay/base}"
all=0
[ "${1:-}" = "--all" ] && all=1

[ -d "$BASE" ] || { echo "No build base at '$BASE'"; exit 1; }
[ -d "$PACKAGES_DIR" ] || { echo "No '$PACKAGES_DIR'"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "Reading $(ls "$PACKAGES_DIR"/*.tar.gz 2>/dev/null | wc -l) packages..."
for p in "$PACKAGES_DIR"/*.tar.gz; do
    [ -e "$p" ] || continue
    tar tzf "$p" 2>/dev/null
done | sed 's|^\./|/|' | grep -v '/$' | grep -v '^/\.meta' | sort -u > "$WORK/packaged"

echo "Reading $BASE..."
sudo find "$BASE" -mindepth 1 \( -type f -o -type l \) -printf '/%P\n' 2>/dev/null \
    | grep -v '^/sources/' | grep -v '^/scripts/' | grep -v '^/tmp/' \
    | sort -u > "$WORK/base"

comm -23 "$WORK/base" "$WORK/packaged" > "$WORK/gap"
[ $all -eq 1 ] || { grep -v '^/tools/' "$WORK/gap" > "$WORK/g2" || true; mv "$WORK/g2" "$WORK/gap"; }

echo
echo "$(wc -l < "$WORK/gap") path(s) in the base and in no package."
echo

# The handful without which a reconstructed root cannot run anything at all.
echo "Needed before anything in such a root can run:"
grep -xE '/bin|/lib|/sbin|/usr/bin/sh|/lib64/ld-linux-x86-64\.so\.2|/lib64/ld-lsb-x86-64\.so\.3|/usr/include/gnu/stubs-64\.h' \
    "$WORK/gap" | sed 's/^/    /' || echo "    (none - they are packaged)"
echo

echo "The rest, by directory:"
sed 's|^\(/usr/include/[^/]*\)/.*|\1/*|; s|^\(/usr/lib/[^/]*\)/.*|\1/*|; s|^\(/tools\)/.*|\1/*|' \
    "$WORK/gap" | sort | uniq -c | sort -rn | head -15 | sed 's/^/  /'
echo
echo "Full list: pass it through 'less'. A recipe which installs these - the
kernel API headers are the bulk of it, and they come from a tools step rather
than a package - would close the gap."
cp "$WORK/gap" "$PACKAGES_DIR/.base-gap" 2>/dev/null \
    || sudo cp "$WORK/gap" "$PACKAGES_DIR/.base-gap"
echo "Written to $PACKAGES_DIR/.base-gap"

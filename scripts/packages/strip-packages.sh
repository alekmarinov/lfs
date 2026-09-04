#!/bin/bash
# Removes the debug symbols from packages already built.
#
#   strip-packages.sh [--dry-run] [package ...]
#
# build-package.sh strips as it builds, so anything built from now on arrives
# stripped. This is for the packages that came before it: rebuilding them from
# source to gain nothing but a smaller file would cost hours, and the result
# would be byte-identical to stripping what is already here.
#
# What it does not touch: the .meta directory. Stripping changes no soname, no
# file list and no identity - the package is the same package, holding the
# same files, with the debug sections removed. So provides, requires, created,
# modified and PKGINFO all stay true, and the version is not bumped.
#
# It rewrites the cache in place, one package at a time through a temporary
# file, so an interruption leaves every package either old or new and none
# half written.
#
# The symbols themselves are gone afterwards - stripping does not set them
# aside, and there is no unstrip. Rebuilding them means 'make packages', which
# is every package compiled again from source. So unless --no-backup is given,
# the untouched package is copied to packages-debug/ first and the whole thing
# becomes a mv away from being undone. It costs the size of the cache in disk,
# which is a rounding error next to recompiling gcc.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
dry=0
backup=1
BACKUP_DIR="${STRIP_BACKUP_DIR:-packages-debug}"
targets=()
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)   dry=1; shift ;;
        --no-backup) backup=0; shift ;;
        -*) echo "unknown option $1"; exit 1 ;;
        *)  targets+=("$1"); shift ;;
    esac
done
[ ${#targets[@]} -gt 0 ] || mapfile -t targets < <(ls "$PACKAGES_DIR"/*.tar.gz 2>/dev/null)
[ ${#targets[@]} -gt 0 ] || { echo "no packages in $PACKAGES_DIR"; exit 1; }

WORK=$(mktemp -d)
trap 'sudo rm -rf "$WORK"' EXIT

total=${#targets[@]}
n=0; saved_k=0; changed=0
for pkg in "${targets[@]}"; do
    n=$((n + 1))
    name=$(basename "$pkg" .tar.gz)
    [ -t 2 ] && printf "\r  %-46s %3d/%d" "$name" "$n" "$total" >&2

    sudo rm -rf "$WORK/x"; mkdir -p "$WORK/x"
    # as the invoking user, so the strip below needs no privilege per file
    tar xzf "$pkg" -C "$WORK/x" --no-same-owner --no-same-permissions 2>/dev/null || {
        echo; echo "  $name: could not be unpacked, left alone"; continue; }

    did=0
    while IFS= read -r -d '' f; do
        [ "$(head -c4 "$f" 2>/dev/null | od -An -tx1 | tr -d ' ')" = "7f454c46" ] || continue
        case "$f" in
        # grub resolves its modules by symbol at load time, so stripping
        # them leaves a boot loader that drops to the rescue shell with
        # "no such partition". build-distro.sh has excluded this path for
        # exactly that reason since before any of this existed; the rule
        # was not carried over when the strip moved here, and the result
        # was an unbootable image.
        */usr/lib/grub/*) continue ;;
            *.a|*.ko) strip --strip-debug    "$f" 2>/dev/null && did=1 ;;
            *)        strip --strip-unneeded "$f" 2>/dev/null && did=1 ;;
        esac
    done < <(find "$WORK/x" -type f -not -path "$WORK/x/tmp/*" -print0 2>/dev/null)

    [ "$did" = 1 ] || continue

    # The original, kept whole, before anything replaces it. Restoring is
    # 'mv packages-debug/<name>.tar.gz packages/'.
    if [ "$dry" = 0 ] && [ "$backup" = 1 ]; then
        mkdir -p "$BACKUP_DIR"
        [ -f "$BACKUP_DIR/$(basename "$pkg")" ] || cp -a "$pkg" "$BACKUP_DIR/"
    fi

    was_k=$(du -sk "$pkg" | cut -f1)
    if [ "$dry" = 1 ]; then
        ( cd "$WORK/x" && tar czf "$WORK/new.tar.gz" . )
    else
        # The modes and ownership the package recorded are restored from the
        # archive it came from, not from what is on disk here: this ran as an
        # ordinary user, so everything unpacked owned by them.
        ( cd "$WORK/x" && sudo tar czf "$WORK/new.tar.gz" --owner=root --group=root . )
        sudo mv "$WORK/new.tar.gz" "$pkg"
    fi
    now_k=$(du -sk "${dry:+$WORK/new.tar.gz}${dry:+}" 2>/dev/null | cut -f1)
    [ "$dry" = 1 ] && now_k=$(du -sk "$WORK/new.tar.gz" | cut -f1) || now_k=$(du -sk "$pkg" | cut -f1)
    saved_k=$((saved_k + was_k - now_k))
    changed=$((changed + 1))
    rm -f "$WORK/new.tar.gz"
done
[ -t 2 ] && printf "\r%-60s\r" "" >&2

echo "  $changed of $total packages had symbols removed"
echo "  $(( saved_k / 1024 )) MB smaller$([ "$dry" = 1 ] && echo ' (dry run, nothing written)')"
if [ "$dry" = 0 ] && [ "$backup" = 1 ]; then
    echo "  originals kept in $BACKUP_DIR/ - restore one with"
    echo "    mv $BACKUP_DIR/<name>.tar.gz $PACKAGES_DIR/"
fi
[ "$dry" = 1 ] || echo "  run 'make packages-meta && make repo' to republish"

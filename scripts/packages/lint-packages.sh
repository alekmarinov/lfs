#!/bin/bash
# Checks what every recipe declares about the package it builds.
#
#   lint-packages.sh [recipe ...]
#
# With no argument it checks every recipe this repository knows, plus the ones
# each distro brings of its own. Run it before 'make packages': the faults it
# reports - an unpinned source glob, a missing version, two recipes claiming
# the same package name - all cost a rebuild to discover otherwise, and one of
# them (a glob matching two tarballs) fails several hours into the build.
#
# Exit status is 1 if any recipe is faulty, so it can gate a build.
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

# shellcheck source=scripts/packages/pkg-header.sh
. "$SCRIPT_DIR/pkg-header.sh"

SOURCES="${LFS_BASE:-overlay/base}/sources"
if [ ! -d "$SOURCES" ]; then
    echo "No sources directory at '$SOURCES'."
    echo "Version is derived from the tarball a recipe pins, so there is nothing"
    echo "to check against until 'make packages' has unpacked the base."
    exit 1
fi

recipes=()
if [ $# -gt 0 ]; then
    recipes=("$@")
else
    while IFS= read -r r; do recipes+=("$r"); done < <(
        ls scripts/packages/lfs/*.sh scripts/packages/blfs/*.sh 2>/dev/null
        ls distros/*/packages/*.sh 2>/dev/null
    )
fi

faulty=0
checked=0
notes=()
# Two recipes may not produce the same name-version-release - a repository
# cannot hold two different things called shadow-4.18.0-1. Sharing a name is
# fine and expected: BLFS rebuilds shadow against Linux-PAM and grub with UEFI
# support, which are the same packages built with more turned on, and RELEASE
# is exactly how a rebuild says it supersedes the earlier one.
#
# The chapter 7 builds are the other case, and not that one: they are
# temporary tools cross compiled to build the system with, never the package
# itself. They take a distinct name and '# CLASS: bootstrap', which is what
# keeps them out of the published repository.
declare -A claimed_by

for recipe in "${recipes[@]}"; do
    [ -f "$recipe" ] || { echo "$recipe: not a file"; faulty=$((faulty + 1)); continue; }
    checked=$((checked + 1))

    if ! pkg_read_headers "$recipe"; then
        echo "$recipe: cannot be read"
        faulty=$((faulty + 1))
        continue
    fi

    # pkg_validate resolves the version as part of checking it, so the value
    # printed below is the one a build would produce. Called directly, never
    # in a command substitution - the derived version would not survive one.
    if ! pkg_validate "$SOURCES"; then
        echo "$recipe:"
        printf '    %s\n' "${PKG_FAULTS[@]}"
        faulty=$((faulty + 1))
        continue
    fi

    id=$(pkg_id)
    if [ -n "${claimed_by[$id]:-}" ]; then
        echo "$recipe:"
        echo "    produces '$id', already produced by ${claimed_by[$id]}"
        echo "    a rebuild with different options bumps '# RELEASE:'; a temporary"
        echo "    chapter 7 build takes a distinct name and '# CLASS: bootstrap'"
        faulty=$((faulty + 1))
        continue
    fi
    claimed_by[$id]="$recipe"

    [ -n "${PKG_NOTE:-}" ] && notes+=("$PKG_RECIPE: $PKG_NOTE")

    if [ "${VERBOSE:-0}" = 1 ]; then
        printf '  %-34s %-30s %-10s %s\n' \
            "$PKG_RECIPE" "$id" "$PKG_CLASS" "${PKG_TARBALL:-—}"
    fi
done

echo
if [ ${#notes[@]} -gt 0 ]; then
    # Not faults - a hand written VERSION which no longer resembles the tarball
    # it names. Usually it is correct and the tarball simply spells the version
    # differently (unzip60.tar.gz is version 6.0). Occasionally it is a version
    # nobody updated when the source moved, which is why it is worth printing.
    echo "${#notes[@]} version(s) worth an eye:"
    printf '    %s\n' "${notes[@]}"
    echo
fi
if [ "$faulty" -gt 0 ]; then
    echo "$faulty of $checked recipes are faulty."
    exit 1
fi
echo "$checked recipes declare a usable package identity."

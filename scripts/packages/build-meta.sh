#!/bin/bash
# Collects what every built package says about itself into one index.
#
#   build-meta.sh [-f] [package ...]
#
# Each package gets a directory under $LFS_PACKAGES/.meta-index/<recipe>/
# holding PKGINFO, provides and requires. build-deps.sh joins those into the
# dependency graph, and 'make repo' will publish them as the repository index.
#
# There are two ways the contents get there, and the difference is only speed:
#
#   from the package    a package built since build-package.sh started writing
#                       .meta/provides carries its own answer, and it is
#                       copied out
#   by scanning         an older package is unpacked and its binaries read,
#                       which is what build-deps.sh used to do for all of them
#
# So this does not require rebuilding anything. The 240 packages already in
# the cache are scanned once, cached, and never scanned again unless they
# change - and everything built from now on arrives with the answer already
# in it.
#
# PKGINFO is never scanned for: name, version, release and class come from the
# recipe, which is where they are declared. A package whose recipe has been
# deleted keeps whatever PKGINFO it was built with.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

# shellcheck source=scripts/packages/pkg-header.sh
. "$SCRIPT_DIR/pkg-header.sh"
# shellcheck source=scripts/packages/pkg-elf.sh
. "$SCRIPT_DIR/pkg-elf.sh"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
INDEX="$PACKAGES_DIR/.meta-index"
SOURCES="${LFS_BASE:-overlay/base}/sources"

o_force=0
targets=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force) o_force=1; shift ;;
        -*)         echo "$(basename "$0"): unknown option $1"; exit 1 ;;
        *)          targets+=("$1"); shift ;;
    esac
done

[ -d "$PACKAGES_DIR" ] || { echo "No '$PACKAGES_DIR' directory, run 'make packages' first"; exit 1; }
sudo mkdir -p "$INDEX"

# One run at a time.
#
# 'make deps' refreshes the index before reading it, so it is easy to start a
# second run while one is going - and they rewrite the same directories. The
# first entry to be caught by that was left with no PKGINFO, no provides and
# no requires, because one run deleted the directory the other was filling.
#
# flock releases the lock when this process exits, however it exits.
LOCK="${TMPDIR:-/tmp}/lfs-build-meta.lock"
exec 9>"$LOCK"
if ! flock -n 9; then
    echo "another build-meta.sh is running (lock: $LOCK); waiting for it"
    flock 9
fi

# Scanning a package means unpacking it, which needs somewhere to put it and
# root to read it back - the trees are owned by root and carry their modes.
WORK=$(mktemp -d)
cleanup() { sudo rm -rf "$WORK"; }
trap cleanup EXIT

# The recipe which built a package, found by the coordinate they share.
find_recipe() {
    local name="$1" r
    for r in "scripts/packages/lfs/$name.sh" "scripts/packages/blfs/$name.sh"; do
        [ -f "$r" ] && { echo "$r"; return 0; }
    done
    # a distro's own recipe
    r=$(ls distros/*/packages/"$name".sh 2>/dev/null | head -1)
    [ -n "$r" ] && { echo "$r"; return 0; }
    return 1
}

if [ ${#targets[@]} -eq 0 ]; then
    mapfile -t targets < <(ls "$PACKAGES_DIR"/*.tar.gz 2>/dev/null)
fi

total=${#targets[@]}
[ "$total" -eq 0 ] && { echo "No packages in '$PACKAGES_DIR'"; exit 0; }

carried=0; scanned=0; fresh=0; count=0
for pkg in "${targets[@]}"; do
    [ -e "$pkg" ] || { echo "no such package: $pkg"; exit 1; }
    name=$(basename "$pkg" .tar.gz)
    count=$((count + 1))
    dir="$INDEX/$name"

    # ---- PKGINFO ----------------------------------------------------------
    # Identity comes from the recipe, not from the package, and reading four
    # comment lines is free - so it is rewritten every run rather than cached.
    # Bumping '# RELEASE:' then shows up in the index without anyone having to
    # remember -f.
    #
    # It also has to come before the freshness test below. When it did not, an
    # entry which had been written while its recipe was momentarily broken kept
    # no PKGINFO, and nothing ever revisited it: the expensive half was up to
    # date, so the whole entry counted as fresh. 'make abi' then refused to
    # fingerprint a core containing a package with no name, which is the right
    # answer to the wrong problem.
    have_recipe=0
    recipe=""
    if recipe=$(find_recipe "$name"); then have_recipe=1; fi

    if [ $have_recipe -eq 1 ]; then
        sudo mkdir -p "$dir"
        if pkg_read_headers "$recipe" && pkg_validate "$SOURCES"; then
            sudo tee "$dir/PKGINFO" > /dev/null <<EOF
name=$PKG_NAME
version=$PKG_VERSION
release=$PKG_RELEASE
arch=${PKG_ARCH:-x86_64}
class=$PKG_CLASS
recipe=$PKG_RECIPE
recipesum=$(pkg_recipe_sum "$recipe")
source=${PKG_TARBALL:-}
runtimerequires=$PKG_RUNTIME_REQUIRES
group=$PKG_GROUP
EOF
        else
            echo
            echo "  $name: recipe declares no usable identity, PKGINFO omitted"
            printf '      %s\n' "${PKG_FAULTS[@]}"
            # a stale one would be worse than none: it would name a version
            # the recipe no longer builds
            sudo rm -f "$dir/PKGINFO"
        fi
    fi

    # ---- provides and requires -------------------------------------------
    # This is the expensive half - unpacking the package and reading its
    # binaries - so it is cached against the tarball's own timestamp, which is
    # what changes when it is rebuilt. The same test 'make' has always used.
    #
    # A package with no recipe here still has to be opened once, to recover the
    # identity it was built with.
    if [ $o_force -eq 0 ] && [ -f "$dir/requires" ] && [ ! "$pkg" -nt "$dir/requires" ] \
       && { [ $have_recipe -eq 1 ] || [ -f "$dir/PKGINFO" ] || [ -f "$dir/no-identity" ]; }; then
        fresh=$((fresh + 1))
        continue
    fi

    [ -t 2 ] && printf "\r  %-52s %3d/%d" "$name" "$count" "$total" >&2
    sudo mkdir -p "$dir"

    # One decompression pass takes everything wanted out of the package: the
    # metadata it may already carry, and otherwise the directories which can
    # hold an ELF file.
    #
    # Asking 'tar tzf' whether .meta/provides exists first cost a second pass
    # over the whole archive - gzip carries no index, so any query
    # decompresses all of it, and these run to hundreds of megabytes each.
    #
    # Unpacked as the invoking user, not with sudo: what comes out is then
    # readable without a privileged process, which is what lets pkg_scan_elf
    # test each file with the shell instead of a pipeline.
    sudo rm -rf "$WORK/x"; mkdir -p "$WORK/x"
    tar xzf "$pkg" -C "$WORK/x" --no-same-owner --no-same-permissions --wildcards \
        './.meta/*' './usr/bin/*' './usr/sbin/*' './usr/libexec/*' './usr/lib/*' \
        > /dev/null 2>&1 || true

    if [ -f "$WORK/x/.meta/provides" ]; then
        sudo cp "$WORK/x/.meta/provides" "$dir/provides"
        sudo cp "$WORK/x/.meta/requires" "$dir/requires"
        carried=$((carried + 1))
    else
        pkg_scan_elf "$WORK/x" "$WORK/provides" "$WORK/requires"
        sudo cp "$WORK/provides" "$dir/provides"
        sudo cp "$WORK/requires" "$dir/requires"
        scanned=$((scanned + 1))
    fi

    # No recipe in this tree - the package came from a distro kept somewhere
    # else. Keep whatever identity it was built with.
    if [ $have_recipe -eq 0 ]; then
        if [ -f "$WORK/x/.meta/PKGINFO" ]; then
            sudo cp "$WORK/x/.meta/PKGINFO" "$dir/PKGINFO"
            sudo rm -f "$dir/no-identity"
        else
            # Nothing here and nothing in the package. Recorded, so the next
            # run does not open a 600 MB tarball to learn the same thing -
            # and cleared the moment its recipe or a rebuilt package turns up.
            sudo touch "$dir/no-identity"
        fi
    fi
done
[ -t 2 ] && printf "\r%-64s\r" "" >&2

echo "  $total packages: $fresh unchanged, $carried carried their own, $scanned scanned"
# Reported by looking at the index rather than by counting during the loop,
# so it says the same thing whether or not anything was re-read this run.
no_identity=()
for d in "$INDEX"/*/; do
    [ -f "$d/PKGINFO" ] || no_identity+=("$(basename "$d")")
done
if [ ${#no_identity[@]} -gt 0 ]; then
    echo "  ${#no_identity[@]} without identity - built from recipes this tree does not have,"
    echo "  and before packages carried their own. They get one when rebuilt:"
    printf '    %s\n' "${no_identity[@]}"
fi
echo "  index in $INDEX"

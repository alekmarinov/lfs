#!/bin/bash
# Builds the recipes a distro brings of its own, into the shared package cache.
#
#   build-distro-packages.sh <name|path>
#
# 'make packages' is distro agnostic on purpose: it builds every package this
# repository knows once, and a distro is assembled by picking from the result.
# That is what makes a second distro cost the base build nothing, and it is the
# whole economic argument for lfs being a tool rather than one appliance's
# build script. So a distro's own recipes are not folded into it. They are a
# small incremental build on top, which is this.
#
# A distro brings them in two directories of its own:
#
#   <distro>/packages/    recipes, named like any other - 'x-make-<name>.sh'
#                         for something not in the book
#   <distro>/sources/     the tarballs they build, and their checksums
#
# Both are staged into the base layer of the build overlay, which is what a
# build sees as '/'. After staging, the recipes are at /scripts/packages/<ID>/
# and their sources at /sources/, which is exactly where a recipe already
# looks - so a distro's recipe is an ordinary recipe and needs to know nothing
# about being external.
#
# The order is the sorted file name, and 'make deps-verify' is what says
# whether that order satisfies the declarations. It is enough for recipes
# appended after everything the book builds: they can depend on what came
# before, and nothing the book builds depends on them. A distro whose recipes
# need each other in some other order will fail deps-verify rather than build
# in the wrong one.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

for var in LFS LFS_BASE LFS_PACKAGE; do
    if [ "${!var}" == "" ]; then
        echo "$(basename "$0"): $var is not defined - run this through 'make distro-packages'"
        exit 1
    fi
done

DISTRO_DIR=$("$BASE_DIR/scripts/resolve-distro.sh" "$1")

# read rather than sourced: distro.conf is configuration, and sourcing it would
# let it set anything in here.
ID=$(sed -n 's/^ID=\"\(.*\)\"$/\1/p; s/^ID=\([^\"]*\)$/\1/p' "$DISTRO_DIR/distro.conf" | tail -1)
case "$ID" in
    "")                echo "$DISTRO_DIR/distro.conf sets no ID"; exit 1 ;;
    *[!a-zA-Z0-9._-]*) echo "ID '$ID' is not usable as a directory name"; exit 1 ;;
esac

if [ ! -d "$DISTRO_DIR/packages" ]; then
    echo "'$ID' brings no recipes of its own, nothing to build"
    exit 0
fi

# Sources first: a recipe verifies its tarball before it builds, so a staged
# recipe with an unstaged tarball fails on the checksum rather than on the
# missing file, which is a worse message.
if [ -d "$DISTRO_DIR/sources" ]; then
    echo "Staging $ID sources into $LFS_BASE/sources"

    # Remove what this distro staged last time, first.
    #
    # Copying alone merges, so an older version of a tarball stays behind
    # beside the new one - and a recipe globbing 'name-*.tar.xz' then hands
    # tar two files, which makes it treat the second as a member name to
    # extract from the first. Measured, with exactly that error, on the first
    # rebuild after a version changed. The distro's own sources/ is cleaned by
    # its stage step; this directory has to be cleaned by whoever fills it.
    #
    # The manifest is how we know what is ours: /sources also holds hundreds
    # of upstream tarballs that must not be touched.
    manifest="$LFS_BASE/sources/.staged-$ID"
    if [ -f "$manifest" ]; then
        while read -r stale; do
            [ -n "$stale" ] && rm -f "$LFS_BASE/sources/$stale"
        done < "$manifest"
    fi

    cp -R "$DISTRO_DIR/sources/." "$LFS_BASE/sources/"
    ( cd "$DISTRO_DIR/sources" && find . -maxdepth 1 -type f -printf '%P\n' ) \
        > "$manifest"
fi

STAGE="$LFS_BASE/scripts/packages/$ID"
echo "Staging $ID recipes into $STAGE"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$DISTRO_DIR/packages/." "$STAGE/"
chmod -R +x "$STAGE"

built=0
for recipe in $(cd "$STAGE" && ls *.sh 2>/dev/null | sort); do
    # A recipe with nothing after '# BUILD_REQUIRES:' is worse than one with no
    # declaration at all: order-deps.sh sees a node with no edges and is free to
    # place it before the compiler. These are the few recipes where declaring
    # them properly can be required, because they are new and there are few.
    if grep -q '^# BUILD_REQUIRES:[[:space:]]*$' "$STAGE/$recipe"; then
        echo "$recipe declares an empty '# BUILD_REQUIRES:'. Fill it in or remove"
        echo "the line - an empty declaration is a node with no edges, and the"
        echo "resolver may place it before the compiler that builds it."
        exit 1
    fi
    # -f, always. Staging is the statement that these sources are new, and the
    # .ready flag is keyed on the recipe name rather than on what it builds —
    # so without this, 'make stage' followed by this script rebuilds nothing,
    # says nothing, and the image quietly keeps the previous renderer. The
    # flag exists to avoid rebuilding the two hundred packages of the book,
    # not the handful a distro brings.
    ./scripts/packages/build-package.sh -f "/scripts/packages/$ID/$recipe"
    built=$((built + 1))
done

echo "Built $built package(s) for '$ID'"

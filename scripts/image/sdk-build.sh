#!/bin/bash
# Builds one package inside the SDK container, without touching this tree.
#
#   sdk-build.sh --recipe <path> [--tag <tag>] [--sources <dir>] [--out <dir>]
#
# WHY THIS EXISTS
#
# build-package.sh overlay-mounts $LFS_BASE under $LFS and works inside it.
# There is one $LFS, so everything serialises on it: while LFS is being
# developed no other project can build a package. A lock now stops the two
# corrupting each other, but a lock only makes them take turns, and a turn can
# be a wpewebkit compile.
#
# A container from lfs-sdk:<tag> has the same shape - the base as a read only
# lower layer, a writable layer on top - and any number run at once. This is
# the step that turns that container back into a package the channel accepts.
#
# WHAT IT DOES NOT DO
#
# Sign or publish. The signing key belongs to whoever owns the channel, and a
# package produced here is an input to 'make repo' like any other. An external
# project produces packages; one machine signs them.
#
# HOW IT DIFFERS FROM build-package.sh
#
# build-package.sh has to work out what its build did, by comparing the upper
# layer against $LFS_BASE and against the previous build of the same package.
# Docker already knows: 'docker diff' reports A, C and D per path. So this
# does not reimplement that inference - it reads it. The classification below
# is a translation, not a second opinion, and that is the only reason having
# two package producers is defensible at all.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

tag=""; recipe=""; sources=""; out=""
while [ $# -gt 0 ]; do
    case "$1" in
        --tag)     tag="$2";     shift 2 ;;
        --recipe)  recipe="$2";  shift 2 ;;
        --sources) sources="$2"; shift 2 ;;
        --out)     out="$2";     shift 2 ;;
        *) echo "unknown argument $1"; exit 1 ;;
    esac
done
[ -n "$recipe" ] || { echo "usage: sdk-build.sh --recipe <path> [--tag <tag>]"; exit 1; }
[ -f "$recipe" ] || { echo "no recipe at '$recipe'"; exit 1; }
: "${tag:=12.4}"
: "${sources:=${LFS_BASE:-overlay/base}/sources}"
: "${out:=${LFS_PACKAGES:-packages}}"
command -v docker > /dev/null || { echo "docker is not installed"; exit 1; }

IMAGE="lfs-sdk:$tag"
sudo docker image inspect "$IMAGE" > /dev/null 2>&1 \
    || { echo "no $IMAGE - build it with 'make sdk-docker TAG=$tag'"; exit 1; }

# The ABI the image was cut from, not the one this tree has now. A package is
# only installable on a system whose core matches what it was compiled
# against, and the image is a snapshot which may be older than this checkout.
ABI=$(sudo docker image inspect "$IMAGE" \
        --format '{{index .Config.Labels "org.intelibo.lfs.abi"}}' 2>/dev/null)
[ -n "$ABI" ] || { echo "$IMAGE carries no ABI label; it was not built by build-sdk-docker.sh"; exit 1; }

. "$BASE_DIR/scripts/packages/pkg-header.sh"
pkg_read_headers "$recipe" || { echo "cannot read the identity headers of $recipe"; exit 1; }
pkg_resolve_version "$sources" > /dev/null 2>&1 || true
name="${PKG_RECIPE:-$(basename "$recipe" .sh)}"

echo "Building $name in $IMAGE"
echo "  ABI      $ABI"
echo "  sources  $sources"

WORK=$(mktemp -d)
CID="lfs-sdk-build-$name-$$"
cleanup() {
    sudo docker rm -f "$CID"           > /dev/null 2>&1 || true
    sudo docker rmi -f "$CID-snapshot" > /dev/null 2>&1 || true
    sudo rm -rf "$WORK"
}
trap cleanup EXIT

# --sources read only: a build must not edit the tarballs it is given, and a
# recipe that tries is a recipe that is not reproducible.
#
# No --privileged and no mount: the container's own writable layer is what the
# overlay was for, so there is nothing left to mount.
sudo docker run --name "$CID" \
    -v "$(readlink -f "$sources")":/sources:ro \
    -v "$(readlink -f "$recipe")":/recipe.sh:ro \
    "$IMAGE" /bin/bash /recipe.sh > "$WORK/build.log" 2>&1 && rc=0 || rc=$?
if [ "$rc" != 0 ]; then
    echo "  build failed (exit $rc); last 25 lines:"
    tail -n 25 "$WORK/build.log" | sed 's/^/    /'
    exit 1
fi

# ---------------------------------------------------------------------------
# The writable layer, as docker already classified it.
# /build is the image's WORKDIR and /sources and /recipe.sh are what we
# mounted, so docker reports all three as additions the build did not make.
# /tmp holds the build's own log, which build-package.sh also keeps out of the
# package. The kernel filesystems are never package content.
sudo docker diff "$CID" > "$WORK/diff" || true
awk '$1=="A"{print substr($0,3)}' "$WORK/diff" | grep -vE '^/(sources|recipe.sh|build|tmp|proc|sys|dev|run)($|/)' > "$WORK/added"    || true
awk '$1=="C"{print substr($0,3)}' "$WORK/diff" | grep -vE '^/(sources|recipe.sh|build|tmp|proc|sys|dev|run)($|/)' > "$WORK/changed"  || true
awk '$1=="D"{print substr($0,3)}' "$WORK/diff" | grep -vE '^/(sources|recipe.sh|build|tmp|proc|sys|dev|run)($|/)' > "$WORK/deleted"  || true
cat "$WORK/added" "$WORK/changed" | sed 's|^/||' | sort -u > "$WORK/paths"
if [ ! -s "$WORK/paths" ] && [ ! -s "$WORK/deleted" ]; then
    echo "  $name wrote no files. The package would be empty, so it is not archived."
    echo "  Check the recipe's '&&' chain, and the tail of the build log:"
    tail -n 25 "$WORK/build.log" | sed 's/^/    /'
    exit 1
fi

# Committed and tarred from inside, rather than 'docker cp' per path: a
# package runs to thousands of files and a copy each is thousands of round
# trips. The commit is a metadata operation, not a copy of the 17 GB base.
sudo docker commit "$CID" "$CID-snapshot" > /dev/null
mkdir -p "$WORK/payload"
sudo docker run --rm -v "$WORK":/w "$CID-snapshot" \
    tar -C / -cf /w/payload.tar --no-recursion -T /w/paths 2>/dev/null || true
sudo tar -C "$WORK/payload" -xf "$WORK/payload.tar" 2>/dev/null || true

# A deletion is a char device in the payload, which is what the overlay upper
# layer means by a whiteout and what copy-or-del.sh and lpkg both read. Without
# this a package could add a file but never remove one.
while IFS= read -r d; do
    [ -n "$d" ] || continue
    rel="${d#/}"
    sudo mkdir -p "$WORK/payload/$(dirname "$rel")"
    sudo mknod "$WORK/payload/$rel" c 0 0 2>/dev/null || true
done < "$WORK/deleted"

# ---------------------------------------------------------------------------
# .meta, the same shape build-package.sh writes.
meta="$WORK/payload/.meta"
sudo mkdir -p "$meta"
sed 's|^/||' "$WORK/added"   | sudo tee "$meta/created"  > /dev/null
sed 's|^/||' "$WORK/changed" | sudo tee "$meta/modified" > /dev/null
sed 's|^/||' "$WORK/deleted" | sudo tee "$meta/removed"  > /dev/null

if [ -r "$BASE_DIR/scripts/packages/pkg-elf.sh" ]; then
    . "$BASE_DIR/scripts/packages/pkg-elf.sh"
    pkg_scan_elf "$WORK/payload" "$WORK/provides" "$WORK/requires" 2>/dev/null || true
    sudo cp "$WORK/provides" "$meta/provides" 2>/dev/null || sudo touch "$meta/provides"
    sudo cp "$WORK/requires" "$meta/requires" 2>/dev/null || sudo touch "$meta/requires"
fi

{
    echo "name=$PKG_NAME"
    echo "version=$PKG_VERSION"
    echo "release=$PKG_RELEASE"
    echo "arch=${PKG_ARCH:-x86_64}"
    echo "class=$PKG_CLASS"
    echo "recipe=$PKG_RECIPE"
    echo "recipesum=$(pkg_recipe_sum "$recipe")"
    echo "source=${PKG_TARBALL:-}"
    echo "abi=$ABI"
    echo "builddate=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} | sudo tee "$meta/PKGINFO" > /dev/null

# Same rules build-package.sh uses, for the same reason: a package is born the
# size it installs at. grub keeps its symbols - it resolves modules by symbol
# at load time and a stripped one drops to the rescue shell.
if [ "${STRIP_PACKAGES:-1}" = 1 ]; then
    while IFS= read -r -d '' f; do
        [ "$(sudo head -c4 "$f" 2>/dev/null | od -An -tx1 | tr -d ' ')" = "7f454c46" ] || continue
        case "$f" in
            */usr/lib/grub/*) continue ;;
            *.a|*.ko) sudo strip --strip-debug    "$f" 2>/dev/null || true ;;
            *)        sudo strip --strip-unneeded "$f" 2>/dev/null || true ;;
        esac
    done < <(sudo find "$WORK/payload" -type f -not -path "$meta/*" -print0 2>/dev/null)
fi

# ---------------------------------------------------------------------------
# Written beside the target and renamed, never in place: 'make repo' hardlinks
# the channel's copy to this inode, and writing straight onto it would rewrite
# whatever the channel already published under that name.
mkdir -p "$out"
pkg="$out/$name.tar.gz"
LOCK="$BASE_DIR/.lfs-packages.lock"
[ -e "$LOCK" ] || : > "$LOCK" 2>/dev/null || true
(
    flock 8
    sudo tar -C "$WORK/payload" -czf "$pkg.new" .
    sudo mv -f "$pkg.new" "$pkg"
) 8<"$LOCK"

echo "  created  $(wc -l < "$WORK/added") file(s)"
echo "  modified $(wc -l < "$WORK/changed") file(s)"
echo "  removed  $(wc -l < "$WORK/deleted") file(s)"
echo "  wrote    $pkg  ($(du -h "$pkg" | cut -f1))"
echo
echo "It reaches the channel the way every other package does:"
echo "    make packages-meta && make repo ARGS=--prune && make publish"

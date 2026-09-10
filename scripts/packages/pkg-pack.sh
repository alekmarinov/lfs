#!/bin/bash
# Turn a finished build inside the SDK container into a package.
#
# Ships in the SDK image at /usr/lib/lpkg/pkg-pack.sh, beside pkg-elf.sh and
# pkg-header.sh, and for the same reason: the shape of a package is this
# repository's to define, and a consumer that reimplements it has to track
# every change to it forever. Two implementations existed for about an hour
# and had already diverged - one of them leaked the image's WORKDIR into the
# payload, the other did not - which is the whole argument in miniature.
#
# It was written in the InteliBoy tree, where the need appeared first, and
# moved here rather than rewritten: it is the tested one.
#
# Runs *in* the container, after the recipe, with the classification handed in
# from the host: docker diff already knows what changed, and the container
# cannot work that out for itself — the layer below it is not visible from
# inside, exactly as an overlay's lower directory is not.
#
#   /work/diff        `docker diff` output, verbatim
#   /work/recipe.sh   the recipe, so pkg-header.sh can read its identity
#   /work/out/        where the tarball is written
#
# What it produces is byte-for-byte the shape build-package.sh produces, and
# it has to be: build-distro.sh unpacks these, lpkg installs them, and
# build-repo.sh publishes them. A package built here is not a different kind
# of package, it is the same package built somewhere that cannot be corrupted
# by somebody else's build.
set -e

DIFF=/work/diff
OUT=/work/out
NAME=${1:?pack.sh needs the package name}
RECIPE=/work/$NAME.sh
STAGE=/tmp/.pkgstage

rm -rf "$STAGE"; mkdir -p "$STAGE/.meta"

# ---------------------------------------------------------------- the files --
#
# docker diff speaks the same three states the overlay does:
#
#   A  added     -> created
#   C  changed   -> modified
#   D  deleted   -> removed   (an overlay says this with a 0:0 char device)
#
# Directories are reported too and are not package contents; a directory that
# only exists because something inside it does is recreated by tar.
: > "$STAGE/.meta/created"
: > "$STAGE/.meta/modified"
: > "$STAGE/.meta/removed"

while read -r state path; do
    [ -n "$path" ] || continue
    # The mount points as well as what is under them. /work and /sources are
    # bind mounts and docker reports the directories themselves as changed, so
    # excluding only their children put "work/" and "sources/" in the payload.
    case "$path" in
        /tmp|/tmp/*|/proc|/proc/*|/sys|/sys/*|/dev|/dev/*|/run|/run/*) continue ;;
        /work|/work/*|/sources|/sources/*) continue ;;
    esac
    rel=${path#/}
    case "$state" in
        D) echo "$rel" >> "$STAGE/.meta/removed" ;;
        A|C)
            # Only files and symlinks. A directory entry from the diff is not
            # content — but a directory the build *created* still has to be
            # carried, or tar recreates it with the wrong mode.
            if [ -L "$path" ] || [ -f "$path" ]; then
                mkdir -p "$STAGE/$(dirname "$rel")"
                cp -a "$path" "$STAGE/$rel"
                # A file already in the base is not necessarily somebody
                # else's. On a rebuild this package's own files are there from
                # its previous build, so docker calls them changed — and
                # build-distro.sh reads that to tell a package replacing a
                # file it owns from several packages each adding to a shared
                # one. The previous package says which are its own; without
                # this, a rebuilt cogiti reported 123 files modified and 10
                # created where it had in fact created all 133.
                if [ "$state" = A ] || grep -qxF "$rel" /work/mine 2>/dev/null; then
                    echo "$rel" >> "$STAGE/.meta/created"
                else
                    echo "$rel" >> "$STAGE/.meta/modified"
                fi
            elif [ -d "$path" ] && [ "$state" = A ]; then
                mkdir -p "$STAGE/$rel"
                chmod --reference="$path" "$STAGE/$rel" 2>/dev/null || true
            fi ;;
    esac
done < "$DIFF"

# A build which touched nothing is a failed build that happened to exit 0 —
# the recipes are long '&&' chains and a broken one leaves the status of the
# last command that ran. Same refusal, same reasoning, as build-package.sh.
if [ ! -s "$STAGE/.meta/created" ] && [ ! -s "$STAGE/.meta/modified" ] \
   && [ ! -s "$STAGE/.meta/removed" ]; then
    echo "pack: the build wrote no files, so there is no package to archive." >&2
    echo "      Check the '&&' chain in $NAME.sh." >&2
    exit 1
fi

# ------------------------------------------------------------------ strip ----
#
# Born the size it installs at. Static archives and kernel modules keep the
# symbols they are linked or resolved against; grub resolves its modules by
# symbol at load time and an unbootable image was the price of forgetting it.
if [ "${STRIP_PACKAGES:-1}" = 1 ]; then
    before=$(du -sk "$STAGE" | cut -f1)
    while IFS= read -r -d '' f; do
        [ "$(head -c4 "$f" 2>/dev/null | od -An -tx1 | tr -d ' ')" = "7f454c46" ] || continue
        case "$f" in
            */usr/lib/grub/*) continue ;;
            *.a|*.ko) strip --strip-debug    "$f" 2>/dev/null ;;
            *)        strip --strip-unneeded "$f" 2>/dev/null ;;
        esac
    done < <(find "$STAGE" -type f -not -path "$STAGE/.meta/*" -print0 2>/dev/null)
    after=$(du -sk "$STAGE" | cut -f1)
    [ "$before" -gt "$after" ] && \
        echo "       stripped $(( (before - after) / 1024 )) MB of debug symbols"
fi

# ------------------------------------------------------- what it needs and has --
if [ -r /usr/lib/lpkg/pkg-elf.sh ]; then
    . /usr/lib/lpkg/pkg-elf.sh
    pkg_scan_elf "$STAGE" "$STAGE/.meta/provides" "$STAGE/.meta/requires"
fi

# ------------------------------------------------------------- what it is ----
#
# The abi is the point of doing this in a labelled image at all. A binary
# needing GLIBC_2.38 asks the loader for libc.so.6 — which is what every glibc
# since 1997 calls itself — so a soname cannot say which core it was compiled
# against. Without this stamp `lpkg install --from` has nothing to check.
if [ -r /usr/lib/lpkg/pkg-header.sh ]; then
    . /usr/lib/lpkg/pkg-header.sh
    if pkg_read_headers "$RECIPE" && pkg_validate /sources; then
        . /etc/lfs-sdk
        {
            echo "name=$PKG_NAME"
            echo "version=$PKG_VERSION"
            echo "release=$PKG_RELEASE"
            echo "arch=${PKG_ARCH:-x86_64}"
            echo "class=$PKG_CLASS"
            echo "recipe=$NAME"
            echo "recipesum=$(pkg_recipe_sum "$RECIPE")"
            echo "source=${PKG_TARBALL:-}"
            echo "abi=$ABI_ID"
            echo "builddate=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        } > "$STAGE/.meta/PKGINFO"
    else
        # Not fatal: the package is good, only its identity is missing, and
        # 'make packages-lint' is where that is meant to be caught.
        echo
        echo "pack: $NAME.sh declares no usable identity, .meta/PKGINFO omitted:"
        printf '    %s\n' "${PKG_FAULTS[@]}"
    fi
fi

mkdir -p "$OUT"
tar cfz "$OUT/$NAME.tar.gz" -C "$STAGE" .

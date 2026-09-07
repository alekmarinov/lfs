#!/bin/bash
# Publishes the built packages as a signed repository.
#
#   build-repo.sh [-o <dir>] [--key <file>] [--no-sign] [--force-stale]
#
# The layout is one channel per ABI, because that is the thing a package is
# compatible with:
#
#   repo/<abi-id>/x86_64/
#       INDEX            one stanza per package
#       INDEX.sig        detached signature over INDEX
#       zlib-1.3.1-1.x86_64.lpkg
#       ...
#
# A repository serves every distro built from the same core - minimal,
# minimal-desktop and full share one channel - because what decides whether a
# package will run is the glibc and openssl it was linked against, not which
# package list happened to include it. distros/*/packages.list is a default
# selection out of the channel, not a separate world.
#
# The file names here are name-version-release.arch, not the recipe
# coordinates the build cache uses. This is where that translation happens and
# the only place it needs to: packages.list, the dependency graph and
# build-distro.sh all go on addressing packages by the script which built them.
#
# Everything but 'bootstrap' is published. Chapter 7's temporary tools are
# built to build the system and are nobody's package. 'core' is published and
# is installable only into an image or a new root, which is what its class
# says; the repository's job is to carry it, not to decide that.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
INDEX_DIR="$PACKAGES_DIR/.meta-index"
ARCH="${PKG_ARCH:-x86_64}"
SOURCES="${LFS_BASE:-overlay/base}/sources"

# shellcheck source=scripts/packages/pkg-header.sh
. "$SCRIPT_DIR/pkg-header.sh"

# the recipe which built a package, found by the coordinate they share
find_recipe() {
    local n="$1" r
    for r in "scripts/packages/lfs/$n.sh" "scripts/packages/blfs/$n.sh"; do
        [ -f "$r" ] && { echo "$r"; return 0; }
    done
    r=$(ls distros/*/packages/"$n".sh 2>/dev/null | head -1)
    [ -n "$r" ] && { echo "$r"; return 0; }
    return 1
}

# The signing key never lives in the repository. .env is committed and already
# carries a root password; a private key must not follow it in. Override with
# REPO_KEY or --key.
#
# Under sudo $HOME is /root, so the invoking user's home is tried too - the
# same fallback publish-repo.sh uses for its credentials. Without it, a
# 'sudo make repo' finds no key where it looked, generates a fresh one below,
# and signs the channel with a key nothing in the field trusts. That failure
# is silent at the point it happens and only shows up as every installed
# system rejecting the next update.
KEY="${REPO_KEY:-}"
if [ -z "$KEY" ]; then
    KEY="$HOME/.config/lfs/repo-signing.key"
    if [ ! -f "$KEY" ] && [ -n "${SUDO_USER:-}" ]; then
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        [ -n "$user_home" ] && [ -f "$user_home/.config/lfs/repo-signing.key" ] \
            && KEY="$user_home/.config/lfs/repo-signing.key"
    fi
fi
OUT="repo"
sign=1
force_stale=0
prune=0
with_source=1

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--out)      OUT="$2"; shift 2 ;;
        --key)         KEY="$2"; shift 2 ;;
        --no-sign)     sign=0; shift ;;
        --force-stale) force_stale=1; shift ;;
        --prune)       prune=1; shift ;;
        --no-source)   with_source=0; shift ;;
        *) echo "$(basename "$0"): unknown argument $1"; exit 1 ;;
    esac
done

# The index is what this reads, so it is brought up to date first.
"$SCRIPT_DIR/build-meta.sh"

# Nothing may be writing the package cache while this runs.
#
# Everything below hardlinks out of $PACKAGES_DIR and records a size and a
# SHA256 for each file. A package still being written by build-package.sh is
# a file that grows, so those two numbers describe a prefix of it - and the
# channel then verifies wrong, which is worse than failing, because the index
# is signed and looks authoritative.
#
# Taken after build-meta.sh rather than before: build-meta is a child process
# and takes a lock of its own, so holding this one across the call would be
# fine, but holding *its* lock would deadlock. Keeping the two separate keeps
# that impossible rather than merely avoided.
#
# flock releases on exit however this exits.
# The lock lives beside this tree, not in /tmp.
#
# /tmp is sticky and world-writable, and with fs.protected_regular set the
# kernel refuses to open a regular file there for writing unless the caller
# owns it - root included, capabilities notwithstanding. These scripts do not
# all run as the same user: build-package.sh runs under sudo, while
# build-meta.sh and build-repo.sh run as the invoking user and elevate per
# command. So whoever created the lock first became the only user who could
# ever take it again, and every later run died with
#   /tmp/lfs-packages.lock: Permission denied
# with deleting the file by hand as the only way out.
#
# The repository root is owned by the user, is not sticky, and root writes
# there regardless - so both callers can always open the lock. $LFS_PACKAGES
# would not do: it is root-owned, which fixes the sudo case and breaks the
# other two.
#
# Opened for READING, not writing. flock(2) locks a descriptor and does not
# care how it was opened, but open(2) for write does care: root creating the
# file leaves it mode 644, and the next non-root run then cannot open it at
# all. Reading needs only the read bit, which 644 grants everyone, so either
# user can take the lock whichever of them created the file.

CACHE_LOCK="$BASE_DIR/.lfs-packages.lock"
[ -e "$CACHE_LOCK" ] || : > "$CACHE_LOCK" 2>/dev/null || true
exec 8<"$CACHE_LOCK"
if ! flock -n 8; then
    echo "a package build is writing the cache (lock: $CACHE_LOCK); waiting for it"
    flock 8
fi

ABI=$("$SCRIPT_DIR/abi-id.sh")

# The human name for this channel, beside the id.
#
# The id is derived and cannot lie about compatibility, which is why it is the
# path. A name is asserted and can, so it is a label only - nothing resolves
# by it without checking the id underneath.
#
# It names both books deliberately. Keying on the LFS version alone is already
# ambiguous here: the channel this replaces was LFS 12.4 with BLFS 11.2, and
# this one is LFS 12.4 with BLFS 12.4. Calling either of them "12.4" would
# describe both.
if [ -z "${LFS_VER:-}" ] && [ -f .env ]; then
    LFS_VER=$(sed -n 's/^LFS_VER=//p' .env | tail -1)
    BLFS_VER=$(sed -n 's/^BLFS_VER=//p' .env | tail -1)
fi
: "${BLFS_VER:=$LFS_VER}"
CHANNEL_NAME="lfs${LFS_VER}-blfs${BLFS_VER}"
CHANNEL="$OUT/$ABI/$ARCH"
echo
echo "Publishing into $CHANNEL"
mkdir -p "$CHANNEL"

PREV="$CHANNEL/INDEX"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# A recipe whose text changed while its RELEASE did not.
#
# RELEASE is bumped by hand, which is readable and will be forgotten. The
# recipe's hash is recorded in every package and in the published index, so a
# forgotten bump is visible here: same name, same version, same release, and a
# different recipe behind it. Publishing that would hand out two different
# packages under one identity, and the second would never reach a system which
# already had the first.
#
# Refusing rather than warning, because a warning in a build log is a warning
# nobody reads. --force-stale is for the case where the change genuinely does
# not affect the output - a comment, a fixed typo in an echo.
declare -A prev_sum
if [ -f "$PREV" ]; then
    while IFS= read -r line; do
        case "$line" in
            "Package: "*)   p=${line#Package: } ;;
            "Version: "*)   v=${line#Version: } ;;
            "Release: "*)   r=${line#Release: } ;;
            "RecipeSum: "*) prev_sum["$p-$v-$r"]=${line#RecipeSum: } ;;
        esac
    done < "$PREV"
fi

# ---------------------------------------------------------------------------
published=0; skipped_bootstrap=0; skipped_noid=0; copied=0; stale=(); wrong_abi=(); unstamped=0
noid=()

: > "$WORK/stanzas"

for dir in "$INDEX_DIR"/*/; do
    [ -d "$dir" ] || continue
    recipe_name=$(basename "$dir")
    pkg="$PACKAGES_DIR/$recipe_name.tar.gz"
    [ -f "$pkg" ] || continue

    if [ ! -f "$dir/PKGINFO" ]; then
        noid+=("$recipe_name")
        skipped_noid=$((skipped_noid + 1))
        continue
    fi

    # read rather than sourced: PKGINFO is data written by the build
    name=$(sed -n 's/^name=//p'      "$dir/PKGINFO")
    version=$(sed -n 's/^version=//p' "$dir/PKGINFO")
    release=$(sed -n 's/^release=//p' "$dir/PKGINFO")
    class=$(sed -n 's/^class=//p'    "$dir/PKGINFO")
    rtreq=$(sed -n 's/^runtimerequires=//p' "$dir/PKGINFO")
    group=$(sed -n 's/^group=//p'    "$dir/PKGINFO")

    # RUNTIME_REQUIRES is written in recipe coordinates, the way the build
    # order refers to things. The channel speaks package names, so it is
    # translated here - the one place holding both, since every index entry is
    # keyed on the coordinate and carries the name.
    rtnames=""
    for co in $rtreq; do
        rn=$(sed -n 's/^name=//p' "$INDEX_DIR/$co/PKGINFO" 2>/dev/null)
        if [ -n "$rn" ]; then
            rtnames="$rtnames $rn"
        else
            echo "  $recipe_name declares runtime dependency '$co', which is in no package"
        fi
    done
    rtnames=${rtnames# }
    recipesum=$(sed -n 's/^recipesum=//p' "$dir/PKGINFO")

    if [ "$class" = bootstrap ]; then
        skipped_bootstrap=$((skipped_bootstrap + 1))
        continue
    fi

    id="$name-$version-$release.$ARCH"
    file="$id.lpkg"

    was=${prev_sum[$name-$version-$release]:-}
    if [ -n "$was" ] && [ -n "$recipesum" ] && [ "$was" != "$recipesum" ]; then
        stale+=("$name-$version-$release ($recipe_name)")
    fi

    # The package says which core it was compiled against; this channel is
    # that core. They disagree when a package was built, then a core library
    # was rebuilt underneath it without rebuilding it - which is precisely the
    # situation the stamp exists to catch, and it is worth catching here
    # rather than on a machine in somebody else's house.
    #
    # Reported, not fatal. Publishing a mismatched package is wrong but
    # publishing nothing is worse, and the stamp is only consulted by
    # 'lpkg install --from': a package fetched from this channel is already
    # known to belong to it by the path it came down.
    if [ "$class" != core ]; then
        if [ -s "$dir/abi" ]; then
            stamped=$(cat "$dir/abi")
            if [ "$stamped" != "$ABI" ]; then
                wrong_abi+=("$name-$version-$release built against $stamped")
            fi
        else
            unstamped=$((unstamped + 1))
        fi
    fi

    # Hardlinked when the repository is on the same filesystem as the cache,
    # so publishing gigabytes costs no disk.
    #
    # It needs sudo, which is not obvious: the packages are mode 644 and
    # readable by anyone, but fs.protected_hardlinks - on by default - lets
    # only the owner of a file, or someone with write access to it, make a new
    # link to it. So an unprivileged 'ln' fails on these root-owned packages
    # and the copy underneath it succeeds, quietly, at a cost of 1.9 GB. That
    # is exactly what happened the first time this ran.
    dest="$CHANNEL/$file"
    if [ ! -e "$dest" ] || [ "$pkg" -nt "$dest" ]; then
        rm -f "$dest"
        ln "$pkg" "$dest" 2>/dev/null \
            || sudo ln "$pkg" "$dest" 2>/dev/null \
            || { cp "$pkg" "$dest"; copied=$((copied + 1)); }
    fi

    size=$(stat -c%s "$dest")
    sha=$(sha256sum "$dest" | cut -d' ' -f1)

    # ---- the source package ------------------------------------------------
    #
    # A recipe, its checksum, and what it needs in order to compile. The
    # tarball it builds is published beside it rather than inside it: several
    # recipes build from one tarball, and the sources run to 2.1 GB, so
    # bundling a copy into every .lsrc would multiply that for nothing. They
    # are hardlinked like the packages, and covered by the same signature
    # because the index carries a hash for each.
    lsrc=""; lsrc_sha=""; src_file=""; src_sha=""; breq=""
    if [ $with_source -eq 1 ] && recipe_path=$(find_recipe "$recipe_name"); then
        pkg_read_headers "$recipe_path"
        # resolves the SOURCE glob and sets PKG_TARBALL - without it the
        # recipe is published with no tarball to build from
        pkg_resolve_version "$SOURCES" > /dev/null 2>&1 || true
        breq="$PKG_BUILD_REQUIRES"
        lsrc="$name-$version-$release.lsrc"

        rm -rf "$WORK/src"; mkdir -p "$WORK/src/.meta"
        cp "$recipe_path" "$WORK/src/recipe.sh"
        {
            echo "name=$name"
            echo "version=$version"
            echo "release=$release"
            echo "class=$class"
            echo "recipe=$recipe_name"
            echo "recipesum=$recipesum"
            echo "source=${PKG_TARBALL:-}"
            echo "buildrequires=$breq"
        } > "$WORK/src/.meta/SRCINFO"
        mkdir -p "$CHANNEL/src"
        tar czf "$CHANNEL/src/$lsrc" -C "$WORK/src" .
        lsrc_sha=$(sha256sum "$CHANNEL/src/$lsrc" | cut -d' ' -f1)

        if [ -n "${PKG_TARBALL:-}" ] && [ -f "$SOURCES/$PKG_TARBALL" ]; then
            src_file="$PKG_TARBALL"
            mkdir -p "$CHANNEL/src/sources"
            sdest="$CHANNEL/src/sources/$src_file"
            if [ ! -e "$sdest" ]; then
                ln "$SOURCES/$src_file" "$sdest" 2>/dev/null \
                    || sudo ln "$SOURCES/$src_file" "$sdest" 2>/dev/null \
                    || cp "$SOURCES/$src_file" "$sdest"
            fi
            src_sha=$(sha256sum "$sdest" | cut -d' ' -f1)
        fi
    fi

    # Sonames on one line each. The fallback list is kept apart because it
    # only resolves a reference when no real SONAME matches - see pkg-elf.sh.
    provides=""; fallback=""
    if [ -f "$dir/provides" ]; then
        provides=$(awk -F'\t' '$2 != "fallback" { printf "%s ", $1 }' "$dir/provides")
        fallback=$(awk -F'\t' '$2 == "fallback" { printf "%s ", $1 }' "$dir/provides")
    fi
    requires=""
    [ -f "$dir/requires" ] && requires=$(tr '\n' ' ' < "$dir/requires")

    {
        echo "Package: $name"
        echo "Version: $version"
        echo "Release: $release"
        echo "Arch: $ARCH"
        echo "Class: $class"
        echo "Recipe: $recipe_name"
        echo "RecipeSum: $recipesum"
        echo "File: $file"
        echo "Size: $size"
        echo "SHA256: $sha"
        [ -n "${provides// /}" ] && echo "Provides: ${provides% }"
        [ -n "${fallback// /}" ] && echo "Provides-Fallback: ${fallback% }"
        [ -n "${requires// /}" ] && echo "Requires: ${requires% }"
        [ -n "$rtnames" ]  && echo "Requires-Package: $rtnames"
        [ -n "$group" ]    && echo "Group: $group"
        [ -n "$breq" ]     && echo "Build-Requires: $breq"
        [ -n "$lsrc" ]     && echo "Source-Package: $lsrc"
        [ -n "$lsrc_sha" ] && echo "Source-Package-SHA256: $lsrc_sha"
        [ -n "$src_file" ] && echo "Source-Tarball: $src_file"
        [ -n "$src_sha" ]  && echo "Source-Tarball-SHA256: $src_sha"
        echo
    } >> "$WORK/stanzas"
    published=$((published + 1))
done

if [ ${#stale[@]} -gt 0 ] && [ $force_stale -eq 0 ]; then
    echo
    echo "${#stale[@]} package(s) would be published under an identity already used"
    echo "for a different recipe:"
    printf '    %s\n' "${stale[@]}"
    echo
    echo "The recipe changed and '# RELEASE:' did not, so a system holding the"
    echo "earlier build would never see this one. Bump RELEASE, or pass"
    echo "--force-stale if the change cannot affect what was built."
    exit 1
fi

# ---------------------------------------------------------------------------
# Files in the channel which the new index does not name.
#
# They appear whenever an identity changes - a RELEASE bump leaves the package
# it superseded sitting there, referenced by nothing. Keeping them is not
# obviously wrong: an old build is what a system would need in order to go
# back to it. But nothing can find them, because the index is the only way in.
#
# So they are reported and left alone, and --prune is how they go. Deleting by
# default would silently discard the only copy of a package somebody had
# published.
orphans=()
while IFS= read -r f; do
    grep -qxF "File: $(basename "$f")" "$WORK/stanzas" || orphans+=("$(basename "$f")")
done < <(find "$CHANNEL" -maxdepth 1 -name '*.lpkg' -print 2>/dev/null)

# ---------------------------------------------------------------------------
{
    echo "# lfs package index"
    echo "ABI: $ABI"
    echo "Channel: $CHANNEL_NAME"
    echo "LFS: $LFS_VER"
    echo "BLFS: $BLFS_VER"
    echo "Arch: $ARCH"
    echo "Packages: $published"
    echo "Created: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    cat "$WORK/stanzas"
} > "$CHANNEL/INDEX"

# ---------------------------------------------------------------------------
# Signed over INDEX alone, which carries a SHA256 for every package - so one
# signature covers the whole channel and a tampered package is caught by its
# hash. Per package signatures would cost more and buy nothing while there is
# one publisher.
if [ $sign -eq 1 ]; then
    if [ ! -f "$KEY" ] && [ -f "$CHANNEL/INDEX.pub" ]; then
        # A channel that already carries a public key has been published, and
        # systems in the field trust that key. Generating a replacement here
        # would sign an update none of them will accept, so this stops rather
        # than guesses which key was meant.
        echo
        echo "No signing key at $KEY, but $CHANNEL/INDEX.pub exists -"
        echo "this channel has already been published under some key. Signing"
        echo "it with a new one makes every system which trusts the old one"
        echo "reject the update."
        echo
        echo "Point at the right key with --key <file> or REPO_KEY, or pass"
        echo "--no-sign to build the channel without signing it."
        exit 1
    fi
    if [ ! -f "$KEY" ]; then
        echo
        echo "No signing key at $KEY - generating one."
        mkdir -p "$(dirname "$KEY")"
        ( umask 077 && openssl genpkey -algorithm ED25519 -out "$KEY" )
        echo "Keep it. Publishing with a different key makes every system which"
        echo "trusts this one reject the channel."
    fi
    openssl pkey -in "$KEY" -pubout -out "$CHANNEL/INDEX.pub" 2>/dev/null
    openssl pkeyutl -sign -rawin -inkey "$KEY" \
        -in "$CHANNEL/INDEX" -out "$CHANNEL/INDEX.sig"

    # Verified immediately, because a signature nobody checks is a file.
    if openssl pkeyutl -verify -rawin -pubin -inkey "$CHANNEL/INDEX.pub" \
        -sigfile "$CHANNEL/INDEX.sig" -in "$CHANNEL/INDEX" > /dev/null 2>&1; then
        echo "  signed and verified"
    else
        echo "  SIGNATURE DID NOT VERIFY - not publishing a channel nobody can trust"
        rm -f "$CHANNEL/INDEX.sig"
        exit 1
    fi
else
    rm -f "$CHANNEL/INDEX.sig"
    echo "  unsigned (--no-sign)"
fi

# ---------------------------------------------------------------------------
if [ ${#wrong_abi[@]} -gt 0 ]; then
    echo
    echo "  ${#wrong_abi[@]} package(s) were compiled against a core that is not $ABI:"
    printf '    %s\n' "${wrong_abi[@]}"
    echo "  Rebuild them, or 'lpkg install --from' will refuse them on a system"
    echo "  running this channel. Installing them from the channel is unaffected."
fi
if [ "$unstamped" -gt 0 ]; then
    echo
    echo "  $unstamped package(s) carry no abi= and cannot be checked by"
    echo "  'lpkg install --from'; they were built before it was recorded."
fi

echo
echo "  $published packages published"
if [ "$copied" -gt 0 ]; then
    echo "  $copied could not be hardlinked and were copied - the channel is"
    echo "  on a different filesystem from $PACKAGES_DIR, and costs its own disk"
fi
[ "$skipped_bootstrap" -gt 0 ] && echo "  $skipped_bootstrap bootstrap packages held back"
if [ "$skipped_noid" -gt 0 ]; then
    echo "  $skipped_noid skipped for having no identity:"
    printf '    %s\n' "${noid[@]}"
fi
if [ ${#orphans[@]} -gt 0 ]; then
    if [ $prune -eq 1 ]; then
        for f in "${orphans[@]}"; do rm -f "$CHANNEL/$f"; done
        echo "  ${#orphans[@]} superseded package(s) pruned"
    else
        echo "  ${#orphans[@]} file(s) in the channel which the index does not name:"
        printf '    %s\n' "${orphans[@]}"
        echo "  they are what earlier identities published; --prune removes them"
    fi
fi
echo "  $CHANNEL"

if [ $sign -eq 1 ]; then
    echo "
INDEX.pub sits beside the index for convenience, and is not what a system
should trust - anyone who can replace INDEX can replace the key next to it.
The public half has to reach a system some other way, baked into the image,
which is what installs it into /etc/lpkg/trusted.pub."
fi

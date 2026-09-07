#!/bin/bash
# The channel directory: which channels exist, what each one is called, and
# which one replaced it.
#
#   build-channels.sh [-o <dir>] [--key <file>] [--no-sign]
#
# WHY THIS EXISTS
#
# A channel is addressed by its ABI id, which is derived and cannot lie about
# compatibility - that is exactly why it is the path. What it cannot do is
# tell anybody what it is or what happened to it. When a core changes, the old
# channel keeps sitting there, still valid, still signed, and silently frozen:
# 'lpkg upgrade' on a machine reading it reports nothing to do, truthfully,
# forever. Nothing in the channel says it has been superseded, and nothing
# says where to go.
#
# This file is what says so. It is a label and succession layer over the ids,
# not a replacement for them: nothing resolves by name without checking the id
# underneath, so a wrong name here cannot make an incompatible package
# installable - lpkg still refuses an index whose ABI is not the system's.
#
# It is stanzas rather than JSON because lpkg parses it, lpkg is shell, and
# the INDEX it already reads is in this format.
#
# It is signed with the same key as the index. Unsigned it would be a redirect
# anyone could forge: the ABI check limits the damage to same-ABI channels,
# but pointing 'stable' at an older channel with the same ABI is a downgrade
# to whatever was vulnerable last month.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

OUT="repo"
KEY="${REPO_KEY:-$HOME/.config/lfs/repo-signing.key}"
sign=1
while [ $# -gt 0 ]; do
    case "$1" in
        -o)        OUT="$2"; shift 2 ;;
        --key)     KEY="$2"; shift 2 ;;
        --no-sign) sign=0; shift ;;
        *) echo "unknown option $1" >&2; exit 1 ;;
    esac
done

[ -d "$OUT" ] || { echo "no repository at '$OUT' - run 'make repo' first" >&2; exit 1; }

CURRENT_ABI=$("$SCRIPT_DIR/abi-id.sh")

# Channels published before the index carried a name. There is one, and its
# id was computed by the scheme abi-id.sh used before the BLFS 12.4 port -
# which hashed every core library's version rather than its soname. Its core
# is ABI-compatible with what that same core computes to now; the id differs
# only because the scheme does. Recorded here so a machine still carrying the
# old id can be told what it maps to instead of being left on a dead path.
legacy_name() {
    case "$1" in
        2d3f09c6c5c6) echo "lfs12.4-blfs11.2" ;;
        *)            echo "" ;;
    esac
}

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
: > "$WORK/stanzas"
current_name=""
found=0

for idx in "$OUT"/*/*/INDEX; do
    [ -f "$idx" ] || continue
    found=$((found + 1))
    d=${idx%/INDEX}; arch=$(basename "$d"); abi=$(basename "$(dirname "$d")")

    get() { sed -n "s/^$1: //p" "$idx" | head -1; }
    name=$(get Channel); lfs=$(get LFS); blfs=$(get BLFS)
    pkgs=$(get Packages); created=$(get Created)
    [ -n "$name" ] || name=$(legacy_name "$abi")
    [ -n "$name" ] || name="legacy-$abi"

    if [ "$abi" = "$CURRENT_ABI" ]; then current_name="$name"; fi

    {
        echo "Channel: $name"
        echo "ABI: $abi"
        [ -n "$lfs" ]  && echo "LFS: $lfs"
        [ -n "$blfs" ] && echo "BLFS: $blfs"
        echo "Arch: $arch"
        [ -n "$pkgs" ]    && echo "Packages: $pkgs"
        [ -n "$created" ] && echo "Created: $created"
        echo "Path: $abi/$arch"
    } >> "$WORK/$abi.stanza"
done

[ "$found" -gt 0 ] || { echo "no channels under '$OUT'" >&2; exit 1; }

# Status needs the current channel to be known first, so it is a second pass.
for f in "$WORK"/*.stanza; do
    [ -f "$f" ] || continue
    abi=$(basename "$f" .stanza)
    {
        cat "$f"
        if [ "$abi" = "$CURRENT_ABI" ]; then
            echo "Status: current"
        else
            echo "Status: superseded"
            [ -n "$current_name" ] && echo "Successor: $current_name"
        fi
        echo
    } >> "$WORK/stanzas"
done

{
    echo "# lfs channel directory"
    echo "Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    [ -n "$current_name" ] && echo "Current: $current_name"
    echo "Alias-stable: ${current_name:-}"
    echo
    cat "$WORK/stanzas"
} > "$OUT/channels"

echo "  $found channel(s) listed in $OUT/channels"
sed -n 's/^Channel: /    /p' "$OUT/channels" | while read -r n; do
    st=$(awk -v N="$n" '$0=="Channel: "N{f=1} f&&/^Status: /{sub(/^Status: /,"");print;exit}' "$OUT/channels")
    printf '    %-24s %s\n' "$n" "$st"
done

if [ $sign -eq 1 ]; then
    [ -f "$KEY" ] || { echo "  no signing key at $KEY - run 'make repo' first" >&2; exit 1; }
    openssl pkeyutl -sign -rawin -inkey "$KEY" -in "$OUT/channels" -out "$OUT/channels.sig"
    openssl pkey -in "$KEY" -pubout -out "$WORK/pub" 2>/dev/null
    if openssl pkeyutl -verify -rawin -pubin -inkey "$WORK/pub" \
        -sigfile "$OUT/channels.sig" -in "$OUT/channels" > /dev/null 2>&1; then
        echo "  signed and verified"
    else
        echo "  SIGNATURE DID NOT VERIFY - not publishing a directory nobody can trust" >&2
        rm -f "$OUT/channels.sig"; exit 1
    fi
else
    rm -f "$OUT/channels.sig"
    echo "  unsigned (--no-sign)"
fi

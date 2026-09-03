#!/bin/bash
# Checks a published channel the way a system installing from it would.
#
#   verify-repo.sh [<channel dir>] [--pub <key>] [--quick]
#
# Three things, in the order that matters:
#
#   1. the signature over INDEX, against a public key given separately
#   2. every package named in INDEX is present, the right size, and hashes to
#      what the index says
#   3. every soname anything requires is provided by something in the channel
#
# The third is what says the channel is closed - installable without reaching
# outside itself. A repository which passes 1 and 2 and fails 3 is signed,
# intact and unable to satisfy an install.
#
# --pub matters. Verifying against the INDEX.pub sitting in the channel proves
# only that whoever wrote the index also wrote the key beside it, which is no
# statement at all. It defaults to that file so the check is runnable right
# after publishing, and says so when it does.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

CHANNEL=""
PUB=""
quick=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --pub)   PUB="$2"; shift 2 ;;
        --quick) quick=1; shift ;;
        *)       CHANNEL="$1"; shift ;;
    esac
done

# With no argument, the channel this tree would publish to.
if [ -z "$CHANNEL" ]; then
    abi=$("$SCRIPT_DIR/abi-id.sh" 2>/dev/null || true)
    [ -n "$abi" ] || { echo "No channel given and no ABI id available"; exit 1; }
    CHANNEL="repo/$abi/${PKG_ARCH:-x86_64}"
fi

[ -f "$CHANNEL/INDEX" ] || { echo "No INDEX in $CHANNEL"; exit 1; }
echo "Checking $CHANNEL"

faults=0

# ---- 1. signature ---------------------------------------------------------
if [ -f "$CHANNEL/INDEX.sig" ]; then
    borrowed=0
    if [ -z "$PUB" ]; then PUB="$CHANNEL/INDEX.pub"; borrowed=1; fi
    if [ ! -f "$PUB" ]; then
        echo "  no public key at $PUB"
        faults=$((faults + 1))
    elif openssl pkeyutl -verify -rawin -pubin -inkey "$PUB" \
            -sigfile "$CHANNEL/INDEX.sig" -in "$CHANNEL/INDEX" > /dev/null 2>&1; then
        if [ $borrowed -eq 1 ]; then
            echo "  signature verifies - against the key in the channel, which"
            echo "  proves only self consistency. Pass --pub with the key the"
            echo "  image trusts to make this mean something."
        else
            echo "  signature verifies against $PUB"
        fi
    else
        echo "  SIGNATURE DOES NOT VERIFY"
        faults=$((faults + 1))
    fi
else
    echo "  unsigned channel"
fi

# ---- 2. the packages ------------------------------------------------------
# One awk pass turns the stanzas into 'file size sha256 name provides requires'
# records, so the shell below reads a line per package instead of re-parsing.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

awk '
    /^Package: /   { name = substr($0, 10) }
    /^File: /      { file = substr($0, 7) }
    /^Size: /      { size = substr($0, 7) }
    /^SHA256: /    { sha  = substr($0, 9) }
    /^Provides: /            { print "P\t" substr($0, 11) > pf }
    /^Provides-Fallback: /   { print "F\t" substr($0, 20) > pf }
    /^Requires: /            { print name "\t" substr($0, 11) > rf }
    /^$/ { if (file != "") print file "\t" size "\t" sha "\t" name; file = "" }
    END  { if (file != "") print file "\t" size "\t" sha "\t" name }
' pf="$WORK/prov" rf="$WORK/req" "$CHANNEL/INDEX" > "$WORK/files"

n=0; missing=0; wrongsize=0; wronghash=0
while IFS=$'\t' read -r file size sha name; do
    n=$((n + 1))
    p="$CHANNEL/$file"
    if [ ! -f "$p" ]; then
        echo "  missing: $file"
        missing=$((missing + 1)); continue
    fi
    if [ "$(stat -c%s "$p")" != "$size" ]; then
        echo "  wrong size: $file"
        wrongsize=$((wrongsize + 1)); continue
    fi
    if [ $quick -eq 0 ]; then
        if [ "$(sha256sum "$p" | cut -d' ' -f1)" != "$sha" ]; then
            echo "  wrong hash: $file"
            wronghash=$((wronghash + 1))
        fi
    fi
done < "$WORK/files"

if [ $quick -eq 1 ]; then
    echo "  $n packages present and the right size (hashes not checked: --quick)"
else
    echo "  $n packages present, the right size and the right hash"
fi
faults=$((faults + missing + wrongsize + wronghash))

# ---- 3. closure -----------------------------------------------------------
# Every soname required by anything, against everything provided. A real
# SONAME wins over a file-name fallback, which is how pkg-elf.sh records them.
cut -f2- "$WORK/prov" 2>/dev/null | tr ' ' '\n' | sort -u > "$WORK/all-provides"
awk -F'\t' '{ n = split($2, s, " "); for (i = 1; i <= n; i++) print $1 "\t" s[i] }' \
    "$WORK/req" 2>/dev/null | sort -u > "$WORK/all-requires"

comm -23 <(cut -f2 "$WORK/all-requires" | sort -u) "$WORK/all-provides" > "$WORK/unmet"
if [ -s "$WORK/unmet" ]; then
    echo "  $(wc -l < "$WORK/unmet") soname(s) required by the channel and provided by nothing in it:"
    while read -r so; do
        who=$(awk -F'\t' -v s="$so" '$2 == s { printf "%s ", $1 }' "$WORK/all-requires")
        echo "    $so  <- $who"
    done < "$WORK/unmet"
    faults=$((faults + 1))
else
    echo "  closed - every soname required is provided within the channel"
fi

echo
if [ "$faults" -gt 0 ]; then
    echo "$faults problem(s)."
    exit 1
fi
echo "Channel is good."

#!/bin/bash
# Lists the files under /etc and /var which more than one package ships.
#
# Those are the files where unpacking in order keeps only the last writer. Most
# are harmless - a package built twice, or a config the later package is meant
# to own - but /etc/passwd is not, and nothing distinguished the two until
# scripts/packages/file-policy.conf said so per path.
#
# The index is written to $LFS_PACKAGES/.files as "<path> <package>..." and is
# what build-distro.sh checks the policy against. /usr is left out on purpose:
# ten thousand of its files are shipped by two packages, almost all of them a
# library legitimately replaced by a rebuild, and the noise would bury the
# forty odd which matter.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
OUT="$PACKAGES_DIR/.files"
WORK=$(mktemp); trap 'rm -f "$WORK"' EXIT

for pkg in "$PACKAGES_DIR"/*.tar.gz; do
    [ -e "$pkg" ] || continue
    name=$(basename "$pkg" .tar.gz)
    sudo tar tzf "$pkg" 2>/dev/null \
        | grep -E '^\./(etc|var)/' \
        | grep -v '/$' \
        | sed "s|^\./|/|; s|\$| $name|"
done | sort > "$WORK"

awk '{ path = $1; pkgs[path] = pkgs[path] " " $2; n[path]++ }
     END { for (p in n) if (n[p] > 1) print p substr(pkgs[p], 0) }' "$WORK" \
    | sort | sudo tee "$OUT" > /dev/null

echo "  $(wc -l < "$OUT") file(s) under /etc or /var are shipped by more than one package"

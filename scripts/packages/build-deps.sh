#!/bin/bash
# Derives the dependency graph of the built packages.
#
# Two kinds of dependency exist and only one of them can be derived:
#
#   build time  what a package needs in order to compile - headers, pkg-config
#               files, code generators. It decides the build order and it is
#               not visible in the result, so it has to be declared by hand in
#               the '# BUILD_REQUIRES:' line of the build script.
#
#   run time    what the built programs need in order to run. For shared
#               libraries this is written in the binaries themselves, so it is
#               computed rather than declared, which is both exact and free to
#               keep up to date.
#
# What this cannot see, and what '# RUNTIME_REQUIRES:' in the build script is
# for: libraries opened with dlopen (pam modules, sudo plugins), programs run
# by other programs (the boot scripts calling ip, hostname, openvt) and data
# files (/etc/services, fonts, terminfo). Those leave no trace in an ELF header.
#
# This used to read the binaries itself, unpacking all 3.3 GB of packages on
# every run. It no longer does: each package records its own provides and
# requires - at build time now, and retrofitted by build-meta.sh for the ones
# built before that - and this is the join over those records. What it reads
# is a few hundred small text files, so it is worth running whenever anything
# is rebuilt rather than once in a while.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
INDEX="$PACKAGES_DIR/.meta-index"
OUT_DEPS="$PACKAGES_DIR/.deps"
OUT_PROVIDES="$PACKAGES_DIR/.deps.provides"
OUT_UNRESOLVED="$PACKAGES_DIR/.deps.unresolved"

[ -d "$PACKAGES_DIR" ] || { echo "No '$PACKAGES_DIR' directory, run 'make packages' first"; exit 1; }

# The index is what this reads, so it is brought up to date first. Packages
# which have not changed since they were last read cost nothing here.
"$SCRIPT_DIR/build-meta.sh"

[ -d "$INDEX" ] || { echo "No metadata index at '$INDEX'"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

: > "$WORK/provides"
: > "$WORK/basenames"
: > "$WORK/needs"

count=0
for dir in "$INDEX"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    count=$((count + 1))

    # provides is 'soname<TAB>soname|fallback'. A fallback is the file name of
    # a library which declares no SONAME of its own - libperl.so and
    # libtcl8.6.so among them - and it resolves a reference only when no real
    # SONAME matches, so the two are kept apart.
    if [ -f "$dir/provides" ]; then
        while IFS=$'\t' read -r soname kind; do
            [ -n "$soname" ] || continue
            case "$kind" in
                fallback) echo "$soname	$name" >> "$WORK/basenames" ;;
                *)        echo "$soname	$name" >> "$WORK/provides" ;;
            esac
        done < "$dir/provides"
    fi

    if [ -f "$dir/requires" ]; then
        while IFS= read -r soname; do
            [ -n "$soname" ] || continue
            echo "$name	$soname" >> "$WORK/needs"
        done < "$dir/requires"
    fi
done
echo "  read $count packages from the index"

# sudo, because $LFS_PACKAGES is written by the build and owned by root
sort -u "$WORK/provides" | sudo tee "$OUT_PROVIDES" > /dev/null
echo "  $(wc -l < "$OUT_PROVIDES") shared libraries provided"

# resolve every needed soname to the package which provides it
sort -u "$WORK/basenames" > "$WORK/basenames.sorted"
sort -u "$WORK/needs" | awk -F'\t' -v provides="$OUT_PROVIDES" -v basenames="$WORK/basenames.sorted" '
BEGIN { while ((getline line < provides)  > 0) { split(line, a, "\t"); owner[a[1]] = a[2] }
        while ((getline line < basenames) > 0) { split(line, a, "\t"); if (!(a[1] in owner)) byname[a[1]] = a[2] } }
{
    who = ($2 in owner) ? owner[$2] : (($2 in byname) ? byname[$2] : "")
    # a package linking against its own library is not an edge
    if (who != "") { if (who != $1) edge[$1] = edge[$1] " " who }
    else           { print $1 "\t" $2 > "/dev/stderr" }
}
END { for (p in edge) { n = split(substr(edge[p], 2), d, " "); delete seen
        out = ""; for (i = 1; i <= n; i++) if (!(d[i] in seen)) { seen[d[i]]; out = out " " d[i] }
        print p "\t" substr(out, 2) } }
' 2> "$WORK/unresolved" | sort | sudo tee "$OUT_DEPS" > /dev/null
sudo cp "$WORK/unresolved" "$OUT_UNRESOLVED"

echo "  $(wc -l < "$OUT_DEPS") packages with resolved dependencies"
unres=$(wc -l < "$OUT_UNRESOLVED")
if [ "$unres" -gt 0 ]; then
    echo "  $unres library references resolved to no package, listed in $OUT_UNRESOLVED"
fi
echo "
The graph is in '$OUT_DEPS', one package per line with the packages it needs.
Query it with 'make why PACKAGE=<name>' or check a distro with 'make deps-check'."

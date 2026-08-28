#!/bin/bash
# Derives the dependency graph of the built packages from the packages
# themselves.
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
#               computed here rather than declared, which is both exact and
#               free to keep up to date.
#
# What this cannot see, and what '# RUNTIME_REQUIRES:' in the build script is
# for: libraries opened with dlopen (pam modules, sudo plugins), programs run
# by other programs (the boot scripts calling ip, hostname, openvt) and data
# files (/etc/services, fonts, terminfo). Those leave no trace in an ELF header.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
OUT_DEPS="$PACKAGES_DIR/.deps"
OUT_PROVIDES="$PACKAGES_DIR/.deps.provides"
OUT_UNRESOLVED="$PACKAGES_DIR/.deps.unresolved"

[ -d "$PACKAGES_DIR" ] || { echo "No '$PACKAGES_DIR' directory, run 'make packages' first"; exit 1; }

WORK=$(mktemp -d)
cleanup() { sudo rm -rf "$WORK"; }
trap cleanup EXIT

echo "Reading the packages in '$PACKAGES_DIR'.."

: > "$WORK/provides"
: > "$WORK/basenames"
: > "$WORK/needs"

count=0
for pkg in "$PACKAGES_DIR"/*.tar.gz; do
    [ -e "$pkg" ] || continue
    name=$(basename "$pkg" .tar.gz)
    count=$((count + 1))
    # the progress line rewrites itself, which only makes sense on a terminal
    [ -t 2 ] && printf "\r  %-52s %3d" "$name" "$count" >&2

    sudo rm -rf "$WORK/x"
    mkdir -p "$WORK/x"
    # only the directories that hold executables and libraries are unpacked,
    # documentation and headers cannot carry an ELF dependency
    sudo tar xzf "$pkg" -C "$WORK/x" --wildcards \
        './usr/bin/*' './usr/sbin/*' './usr/libexec/*' './usr/lib/*' \
        > /dev/null 2>&1 || true
    [ -d "$WORK/x" ] || continue

    # an ELF file starts with \x7fELF, which is cheaper to test than running
    # file(1) on every one of them
    while IFS= read -r -d '' f; do
        [ "$(head -c4 "$f" 2>/dev/null | od -An -tx1 | tr -d ' ')" = "7f454c46" ] || continue
        # A few libraries carry no SONAME at all - libperl.so and libtcl8.6.so
        # among them - so the file name is recorded as well and used when the
        # SONAME lookup finds nothing. Without it their own package appears to
        # depend on a library nothing provides.
        readelf -d "$f" 2>/dev/null | awk -v p="$name" -v b="$(basename "$f")" '
            /\(SONAME\)/  { gsub(/.*\[|\].*/, ""); print "P\t" $0 "\t" p }
            /\(NEEDED\)/  { gsub(/.*\[|\].*/, ""); print "N\t" $0 "\t" p }
            END           { if (b ~ /\.so/) print "B\t" b "\t" p }
        '
    done < <(sudo find "$WORK/x" -type f -print0 2>/dev/null) \
        | sort -u \
        | while IFS=$'\t' read -r kind soname owner; do
              case "$kind" in
                  P) echo "$soname	$owner" >> "$WORK/provides" ;;
                  B) echo "$soname	$owner" >> "$WORK/basenames" ;;
                  N) echo "$owner	$soname" >> "$WORK/needs" ;;
              esac
          done
done
[ -t 2 ] && printf "\r%-60s\r" "" >&2
echo "  read $count packages"

sort -u "$WORK/provides" | sudo tee "$OUT_PROVIDES" > /dev/null
echo "  $(wc -l < "$OUT_PROVIDES") shared libraries provided"

# resolve every needed soname to the package which provides it
sort -u "$WORK/basenames" > "$WORK/basenames.sorted"
sort -u "$WORK/needs" | awk -F'\t' -v provides="$OUT_PROVIDES" -v basenames="$WORK/basenames.sorted" '
BEGIN { while ((getline line < provides)  > 0) { split(line, a, "\t"); owner[a[1]] = a[2] }
        while ((getline line < basenames) > 0) { split(line, a, "\t"); if (!(a[1] in owner)) byname[a[1]] = a[2] } }
{
    who = ($2 in owner) ? owner[$2] : (($2 in byname) ? byname[$2] : "")
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

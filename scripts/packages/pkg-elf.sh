#!/bin/bash
# Reads the shared library dependencies out of a built tree.
#
# Sourced, not executed. This is the half of build-deps.sh which looks at
# binaries, lifted out so that it runs in two places rather than one:
#
#   build-package.sh   over the overlay upper layer it has just built, which
#                      is already unpacked and costs nothing to walk
#   build-meta.sh      over a package tarball built before that existed
#
# Both write the same two files, so a package describes its own linkage and
# the graph is a join over those descriptions instead of a rescan of every
# tarball in the cache.
#
# What is read is exact, because it is in the binaries: DT_SONAME is what a
# library calls itself and DT_NEEDED is what an executable asks the loader
# for. What is not here is everything ELF cannot express - a dlopened module,
# a program run by another program, a data file - and that stays declared by
# hand in '# RUNTIME_REQUIRES:'.

# pkg_scan_elf <root> <provides-file> <requires-file>
#
# The tree has to be readable by the caller. Whoever unpacks it is responsible
# for that, which is cheaper than reading it back through a privileged process
# - see the magic number test below.
pkg_scan_elf() {
    local root="$1" provides="$2" requires="$3"

    : > "$provides"
    : > "$requires"
    [ -d "$root" ] || return 0

    # Only where executables and libraries live. Headers and documentation
    # cannot carry an ELF dependency, and /usr/share is the bulk of the tree.
    local dirs=()
    local d
    for d in usr/bin usr/sbin usr/libexec usr/lib lib bin sbin; do
        [ -d "$root/$d" ] && dirs+=("$root/$d")
    done
    [ ${#dirs[@]} -eq 0 ] && return 0

    # An ELF file starts with \x7fELF, and the test is done by bash reading
    # four characters rather than by a pipeline.
    #
    # It used to be 'head -c4 | od | tr', which is three processes for every
    # file in the tree - and most of a tree is not ELF. The python package
    # alone carries several thousand .py files, and reading them that way took
    # longer than everything else in the scan put together. 'read -N4' spawns
    # nothing, and readelf then runs only for the files which really are ELF.
    #
    # A non-ELF file whose first bytes contain a NUL gives read a short
    # result, which cannot equal the magic, so it is skipped like any other.
    #
    # A few libraries carry no SONAME at all (libperl.so and libtcl8.6.so
    # among them), so the file name is recorded as a fallback. Without it
    # their own package appears to depend on a library nothing provides.
    local f magic
    while IFS= read -r -d '' f; do
        magic=""
        IFS= read -r -N4 magic < "$f" 2>/dev/null || true
        [ "$magic" = $'\x7fELF' ] || continue
        readelf -d "$f" 2>/dev/null | awk -v b="${f##*/}" '
            /\(SONAME\)/ { gsub(/.*\[|\].*/, ""); print "P\t" $0 }
            /\(NEEDED\)/ { gsub(/.*\[|\].*/, ""); print "N\t" $0 }
            END          { if (b ~ /\.so/) print "B\t" b }
        '
    done < <(find "${dirs[@]}" -type f -print0 2>/dev/null) \
        | sort -u \
        | while IFS=$'\t' read -r kind soname; do
              case "$kind" in
                  P) echo "$soname"      >> "$provides" ;;
                  B) echo "$soname	fallback" >> "$provides" ;;
                  N) echo "$soname"      >> "$requires" ;;
              esac
          done

    # A basename fallback must not displace a real SONAME from the same
    # package - and a library which does declare one lands in both lists.
    if [ -s "$provides" ]; then
        awk -F'\t' '
            NR == FNR { if (NF == 1) real[$1]; next }
            NF == 1 || !($1 in real) { print $1 "\t" (NF == 1 ? "soname" : "fallback") }
        ' "$provides" "$provides" | sort -u > "$provides.tmp"
        mv "$provides.tmp" "$provides"
    fi
    sort -u -o "$requires" "$requires"
    return 0
}

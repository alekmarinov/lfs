#!/bin/bash
# The fingerprint of the core these packages were compiled against.
#
#   abi-id.sh            print the id
#   abi-id.sh -v         print it, and what went into it
#
# Every package in the cache is compiled against one exact core, and a package
# is only installable on a system built from a compatible one. Nothing in a
# package says so - a binary linked against libssl.so.3 installs perfectly
# happily onto a system carrying libssl.so.1.1 and fails when it is first run,
# which may be on a machine nobody is looking at.
#
# So the core is fingerprinted and the result travels with everything: stamped
# into /etc/os-release of an assembled distro, written into each package as
# 'abi=', and used as the channel a repository is published under. An 'lpkg'
# refusing a channel whose id is not its own is the check that cannot be
# forgotten, because it needs nobody to remember it.
#
# WHAT GOES INTO IT
#
# Two different things, because two different things can break a binary and
# only one of them is visible as a soname.
#
#   the toolchain - glibc and gcc - by name, version and release.
#
#     These are the packages whose compatibility a soname cannot express.
#     libc.so.6 has been the soname of every glibc since 1997, so it says
#     nothing about whether GLIBC_2.38 is present; that lives in symbol
#     versions, in .gnu.version_r, which nothing here reads. Same for
#     libstdc++.so.6 and the GLIBCXX_ versions gcc puts in it. Hashing their
#     versions is what stands in for the symbol versions.
#
#   everything else in the core - by the sonames it provides.
#
#     A soname is the compatibility promise: libcurl.so.4 means the same
#     interface whether the package is 7.84 or 8.15, and upstream changes it
#     to libcurl.so.5 exactly when that stops being true. So the soname set is
#     hashed and the versions are ignored.
#
# WHY NOT VERSIONS FOR EVERYTHING
#
# That is what this did until the BLFS 12.4 port, and it was wrong in a way
# that cost a reimage. The id hashed name-version-release of every core
# package providing a library, so it changed when curl went 7.84 -> 8.15 even
# though the soname stayed libcurl.so.4, glibc was byte for byte identical,
# and nothing compiled against the old core could fail on the new one. The
# effect was that a curl security update - precisely the update most worth
# shipping - minted a new channel and stranded every installed machine, for a
# drop-in replacement.
#
# Only the real DT_SONAME entries count, not the 'fallback' lines. A fallback
# is the file name of a library which carries no soname of its own, and it
# has the version in it - libcurl.so.4.8.0 - so counting those would put the
# churn straight back.
#
# It follows that the id still changes for the things that genuinely break a
# binary: a new glibc or gcc, a library leaving the core, or a soname bump
# such as libssl.so.3 -> libssl.so.4. binutils is an honest example of the
# last one: its sonames are libbfd-2.45.so and libopcodes-2.45.so, so a
# binutils bump does change the id - correctly, because the loader will not
# find the old name.
#
# Packages providing no library at all are not part of this. Half the core is
# sed, tar, grep, the bootscripts, lpkg itself, and nothing is compiled
# against any of them.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

PACKAGES_DIR="${LFS_PACKAGES:-packages}"
INDEX="$PACKAGES_DIR/.meta-index"
CORE_LIST="distros/core/packages.list"
ARCH="${PKG_ARCH:-x86_64}"

# The packages whose ABI is not expressible as a soname. By package name, not
# by recipe: the recipe is a coordinate of this tree, the name is what the
# package calls itself.
TOOLCHAIN="glibc gcc"

verbose=0
[ "${1:-}" = "-v" ] && verbose=1

[ -f "$CORE_LIST" ] || { echo "No $CORE_LIST" >&2; exit 1; }
[ -d "$INDEX" ] || {
    echo "No metadata index at '$INDEX' - run 'make packages-meta' first" >&2
    exit 1
}

missing=0
skipped=0
tool_ids=()
sonames=()
while read -r pkg; do
    case "$pkg" in ''|\#*) continue ;; esac
    name=${pkg%.tar.gz}
    info="$INDEX/$name/PKGINFO"
    if [ ! -f "$info" ]; then
        echo "$name: no PKGINFO in the index" >&2
        missing=$((missing + 1))
        continue
    fi
    # read rather than sourced: PKGINFO is data
    n=$(sed -n 's/^name=//p' "$info")

    case " $TOOLCHAIN " in
        *" $n "*)
            v=$(sed -n 's/^version=//p' "$info")
            r=$(sed -n 's/^release=//p' "$info")
            tool_ids+=("$n-$v-$r")
            continue
            ;;
    esac

    # no shared library, no way for a binary to be incompatible with it
    if [ ! -s "$INDEX/$name/provides" ]; then
        skipped=$((skipped + 1))
        continue
    fi
    while IFS=$'\t' read -r so kind; do
        [ "$kind" = soname ] || continue
        # Only names that look like a shared library. bash sets a DT_SONAME on
        # each of its 40 loadable builtins - /usr/lib/bash/accept, basename,
        # chmod and the rest - so without this the core's fingerprint carries
        # 40 entries which are dlopen'd by path and which nothing can link
        # against: measured over the whole tree, not one DT_NEEDED anywhere
        # lacks '.so'. They would also churn the id whenever bash gained or
        # lost a loadable, which is the class of false alarm this scheme
        # exists to remove.
        #
        # This filter is for the fingerprint only. The provides and requires
        # files keep every name, so if anything ever did link one of these,
        # dependency resolution still finds it.
        case "$so" in *.so|*.so.*) ;; *) continue ;; esac
        sonames+=("$so")
    done < "$INDEX/$name/provides"
done < "$CORE_LIST"

if [ "$missing" -gt 0 ]; then
    echo "$missing core package(s) are not in the index; the id would not describe the core" >&2
    exit 1
fi

for t in $TOOLCHAIN; do
    case " ${tool_ids[*]} " in
        *" $t-"*) ;;
        *) echo "$t is not in $CORE_LIST, so the id would not describe the toolchain" >&2
           exit 1 ;;
    esac
done

# Sorted and deduplicated, so the id depends on what the core is and not on
# the order somebody happened to list it in, nor on two packages shipping the
# same soname.
mapfile -t sorted_tools < <(printf '%s\n' "${tool_ids[@]}" | sort)
mapfile -t sorted_sos   < <(printf '%s\n' "${sonames[@]}"  | sort -u)

# 12 hex characters. Long enough that two different cores will not collide in
# any repository anyone will host, short enough to read out of os-release and
# to sit in a URL path.
id=$(printf '%s\n' "$ARCH" "${sorted_tools[@]}" "${sorted_sos[@]}" | sha256sum | cut -c1-12)

if [ "$verbose" = 1 ]; then
    echo "arch: $ARCH"
    echo "toolchain (hashed by version):"
    printf '  %s\n' "${sorted_tools[@]}"
    echo "${#sorted_sos[@]} soname(s) from the rest of the core:"
    printf '  %s\n' "${sorted_sos[@]}"
    echo "$skipped core package(s) provide no library and are not part of the ABI"
    echo
fi
echo "$id"

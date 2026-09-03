#!/bin/bash
# Reads the identity a recipe declares about the package it builds.
#
# Sourced, not executed. Every caller which needs to know what a recipe
# produces - build-package.sh writing .meta/PKGINFO, lint-packages.sh checking
# the declarations, and later 'make repo' naming the published artifact - goes
# through here, so there is one parser and one version rule rather than a
# regular expression per caller.
#
# A recipe declares itself in its comment header, the same way it already
# declares BUILD_REQUIRES:
#
#   # PACKAGE:  zlib              what this builds, in upstream's name for it
#   # SOURCE:   zlib-*.tar.xz     the tarball, pinned to exactly one file
#   # VERSION:  1.3.1             only when SOURCE cannot give it - see below
#   # RELEASE:  1                 bumped by hand when the recipe changes
#   # CLASS:    core              core | system | extra | bootstrap
#
# The version rule is: VERSION is whatever the first '*' of SOURCE matched.
#
# That one rule covers every naming convention in the book without a table of
# special cases - 'zlib-*.tar.xz' gives 1.3.1, 'tcl*-src.tar.gz' gives 8.6.16,
# 'expect*.tar.gz' gives 5.45.4 - because the '*' is already sitting exactly
# where the version is. What it demands in return is that SOURCE match one
# file and no more, which is a requirement worth having on its own: the
# recipes glob loosely today and several of them resolve to the wrong tarball.
# 'Python-*.tar.xz' matches both Python-3.13.7 and Python-3.10.18, and
# 'Linux-PAM-*.tar.xz' matches the -docs archive before the source. A glob
# handed to tar as two arguments makes tar read the second as a member name of
# the first, which is how this fails - noisily if you are lucky.
#
# VERSION is declared explicitly instead of derived when there is no single
# tarball to derive it from:
#
#   scaffolding       7.5-create-directories and the configure-* steps build
#                     no upstream source at all
#   bundles           24-make-xorg-libraries builds a list of tarballs in a
#                     loop; no one of them is the version
#   non-tarballs      x-make-ca-certificates builds certdata.txt
#   embedded versions unzip60.tar.gz carries no separator to split on
#
# Declaring both SOURCE and VERSION is allowed and means "pin this tarball,
# but the version is not what the glob says".

# Fills PKG_NAME PKG_SOURCE PKG_VERSION PKG_RELEASE PKG_CLASS from a recipe.
# Unset fields come back empty. Returns 1 only if the file cannot be read;
# whether the declarations are complete is pkg_validate's question, so that a
# linter can report every fault of a recipe rather than only the first.
pkg_read_headers() {
    local recipe="$1"
    [ -r "$recipe" ] || return 1

    PKG_NAME=""; PKG_SOURCE=""; PKG_VERSION=""; PKG_RELEASE=""; PKG_CLASS=""
    PKG_BUILD_REQUIRES=""
    PKG_RUNTIME_REQUIRES=""
    PKG_GROUP=""
    PKG_NOTE=""
    PKG_FAULTS=()
    PKG_RECIPE=$(basename "$recipe" .sh)

    # Every comment line in the file is considered, not only a block at the
    # top. That is the convention already in use: order-deps.sh reads
    # '# BUILD_REQUIRES:' with a line-anchored match anywhere in the recipe,
    # and most recipes put their declarations below 'set -e' and the echo
    # lines rather than above them. Matching that means one rule for all the
    # headers instead of two places to look.
    #
    # The first occurrence of a key wins, so a declaration cannot be quietly
    # overridden further down.
    local line key value
    while IFS= read -r line; do
        case "$line" in
            "#"*) ;;
            *)    continue ;;
        esac
        key=${line#\#}
        key=${key%%:*}
        # ${var// /} rather than a call out to tr: this runs once per recipe
        # per lint, and 234 recipes is enough for the difference to show.
        key=${key// /}
        case "$key" in
            PACKAGE|SOURCE|VERSION|RELEASE|CLASS) ;;
            BUILD_REQUIRES|RUNTIME_REQUIRES|GROUP) ;;
            *) continue ;;
        esac
        value=${line#*:}
        # strip surrounding whitespace, and an inline trailing comment - the
        # headers are read by people too, and several want a note beside them
        value=${value%%  \#*}
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        case "$key" in
            PACKAGE) [ -z "$PKG_NAME" ]    && PKG_NAME="$value" ;;
            SOURCE)  [ -z "$PKG_SOURCE" ]  && PKG_SOURCE="$value" ;;
            VERSION) [ -z "$PKG_VERSION" ] && PKG_VERSION="$value" ;;
            RELEASE) [ -z "$PKG_RELEASE" ] && PKG_RELEASE="$value" ;;
            CLASS)   [ -z "$PKG_CLASS" ]   && PKG_CLASS="$value" ;;
            # Not validated here: order-deps.sh owns the build order and is
            # where an empty or wrong declaration is caught. This only carries
            # it, so a source package can say what it needs to compile.
            BUILD_REQUIRES) [ -z "$PKG_BUILD_REQUIRES" ] && PKG_BUILD_REQUIRES="$value" ;;
            # What a package needs in order to run and no binary mentions:
            # a dlopened module, a program it execs, a data file it reads.
            # Xorg cannot start without the XKB rule files in
            # xkeyboard-config, and nothing links them - so without this the
            # X server installs perfectly and dies on first use.
            RUNTIME_REQUIRES) [ -z "$PKG_RUNTIME_REQUIRES" ] && PKG_RUNTIME_REQUIRES="$value" ;;
            # Named sets a person can ask for: 'lpkg install @xorg'. A group
            # is not a dependency - firefox does not depend on an X server,
            # and saying it did would drag one onto a headless machine - it is
            # a way of saying "the things that together make X work here".
            GROUP) [ -z "$PKG_GROUP" ] && PKG_GROUP="$value" ;;
        esac
        # the assignments above are conditional, and the last one failing its
        # test must not end the loop under a caller running with 'set -e'
        true
    done < "$recipe"

    [ -n "$PKG_RELEASE" ] || PKG_RELEASE=1
    return 0
}

# Resolves PKG_SOURCE against a sources directory and derives PKG_VERSION from
# it. Does nothing when the recipe declared VERSION itself. Sets PKG_TARBALL to
# the file which matched, so a caller can record what was actually built.
#
# Prints the reason and returns non zero when the glob matches no file or more
# than one. Both are faults the recipe has to fix - an unresolvable pin is a
# missing download, and an ambiguous one is the tar-eats-two-arguments bug
# waiting for the next rebuild.
pkg_resolve_version() {
    local sources="$1"
    PKG_TARBALL=""

    if [ -z "$PKG_SOURCE" ]; then
        [ -n "$PKG_VERSION" ] && return 0
        PKG_FAULTS+=("declares neither SOURCE nor VERSION")
        return 1
    fi

    local matches=()
    # A subshell so the caller's working directory and nullglob are untouched.
    # mapfile over compgen keeps names with spaces in one piece; none have them
    # today, and relying on that is how they get broken later.
    mapfile -t matches < <(cd "$sources" 2>/dev/null && compgen -G "$PKG_SOURCE")

    case ${#matches[@]} in
        0) PKG_FAULTS+=("SOURCE '$PKG_SOURCE' matches no file in $sources")
           return 1 ;;
        1) ;;
        *) PKG_FAULTS+=("SOURCE '$PKG_SOURCE' matches ${#matches[@]} files: ${matches[*]}"
                        "    pin it to one - an ambiguous glob reaches tar as several arguments")
           return 1 ;;
    esac

    PKG_TARBALL="${matches[0]}"

    local pre rest suf v
    pre=${PKG_SOURCE%%\**}      # literal before the first *
    rest=${PKG_SOURCE#*\*}      # everything after it
    suf=${rest%%\**}            # literal up to the second *, or to the end

    if [ -n "$PKG_VERSION" ]; then
        # Declared explicitly, so nothing to derive - but a hand written
        # version goes stale the moment the tarball is upgraded and nothing
        # else would notice. Say so when it no longer looks like the file it
        # describes. A note rather than a fault: 'unzip60.tar.gz' really is
        # version 6.0 and never will contain the string.
        case "$PKG_TARBALL" in
            *"$PKG_VERSION"*) ;;
            *) PKG_NOTE="VERSION '$PKG_VERSION' does not appear in '$PKG_TARBALL'" ;;
        esac
        return 0
    fi

    # The version is the text the first '*' matched, which is read off by
    # removing the literal on either side of it. That only works when those
    # literals really are literal: a pin like 'Linux-PAM-[0-9]*[0-9].tar.xz'
    # uses a pattern to exclude the -docs archive, and the version then
    # straddles the pattern rather than sitting inside the '*'. Stripping
    # 'Linux-PAM-[0-9]' off the front eats the leading 1 and yields '.5.2'.
    #
    # Refusing is what keeps that from passing quietly. Before this check,
    # 'freetype-[0-9]*.tar.xz' derived the version 'freetype-2.12.1' and the
    # linter was satisfied with it.
    case "$pre$suf" in
        *[][?]*)
            PKG_FAULTS+=("SOURCE '$PKG_SOURCE' patterns around the '*', so the version"
                         "    cannot be read off it - declare '# VERSION:' explicitly")
            return 1 ;;
    esac

    v=${PKG_TARBALL#"$pre"}
    [ -n "$suf" ] && v=${v%%"$suf"*}

    # A version which does not begin with an alphanumeric has been cut in the
    # middle. It happens when the pin puts part of the version in its literal
    # prefix in order to be unambiguous: 'Python-3.13*.tar.xz' has to name the
    # series to avoid also matching Python-3.10.18, and the '*' is then left
    # matching only '.7'. Explicit VERSION is the answer, and this is what
    # stops '.7' from being accepted as one.
    case "$v" in
        [a-zA-Z0-9]*) ;;
        *) PKG_FAULTS+=("version '$v' derived from '$PKG_TARBALL' is cut short - the pin"
                        "    '$PKG_SOURCE' holds part of the version, so declare '# VERSION:'")
           return 1 ;;
    esac

    if [ -z "$v" ] || [ "$v" = "$PKG_TARBALL" ]; then
        PKG_FAULTS+=("could not read a version out of '$PKG_TARBALL' using '$PKG_SOURCE'"
                     "    declare '# VERSION:' explicitly")
        return 1
    fi
    PKG_VERSION="$v"
    return 0
}

# Fills PKG_FAULTS with everything wrong in what a recipe declared, and
# returns non zero if there was anything. Reporting all of them matters: a
# recipe missing three headers should cost one lint run to fix, not three.
#
# The faults go in an array rather than to stdout so that a caller can read
# them without a command substitution. That is not a style preference - the
# version is derived here, and a subshell would throw it away. Every derived
# version came back empty until this stopped echoing.
pkg_validate() {
    local sources="$1"

    if [ -z "$PKG_NAME" ]; then
        PKG_FAULTS+=("declares no '# PACKAGE:'")
    else
        case "$PKG_NAME" in
            *[!a-zA-Z0-9._+-]*)
                PKG_FAULTS+=("PACKAGE '$PKG_NAME' has characters which cannot go in a file name") ;;
        esac
    fi

    case "$PKG_CLASS" in
        core|system|extra|bootstrap) ;;
        "") PKG_FAULTS+=("declares no '# CLASS:' - core, system, extra or bootstrap") ;;
        *)  PKG_FAULTS+=("CLASS '$PKG_CLASS' is not core, system, extra or bootstrap") ;;
    esac

    case "$PKG_RELEASE" in
        ""|*[!0-9]*) PKG_FAULTS+=("RELEASE '$PKG_RELEASE' is not a number") ;;
    esac

    pkg_resolve_version "$sources" || true

    if [ -n "$PKG_VERSION" ]; then
        case "$PKG_VERSION" in
            *[!a-zA-Z0-9._+~-]*)
                PKG_FAULTS+=("VERSION '$PKG_VERSION' has characters which cannot go in a file name") ;;
        esac
        # A version with no digit in it is almost always the glob having
        # matched something other than the source tarball.
        case "$PKG_VERSION" in
            *[0-9]*) ;;
            *) PKG_FAULTS+=("VERSION '$PKG_VERSION' contains no digit - check what SOURCE matched") ;;
        esac
    fi

    [ ${#PKG_FAULTS[@]} -eq 0 ]
}

# name-version-release.arch, the identity a repository indexes and publishes.
# The build cache keeps its recipe-coordinate file names; this is what those
# artifacts are called once they leave it.
pkg_id() {
    echo "$PKG_NAME-$PKG_VERSION-$PKG_RELEASE.${PKG_ARCH:-x86_64}"
}

# The recipe's own content, hashed.
#
# RELEASE is bumped by hand, which is readable and will be forgotten at least
# once. This is what makes a forgotten bump detectable rather than silent: the
# published index carries it, so 'make repo' can see a recipe whose text
# changed while its RELEASE did not, and say so. It is a check, not the
# version - deriving RELEASE from it would make the number unreadable.
pkg_recipe_sum() {
    sha256sum "$1" | cut -d' ' -f1
}

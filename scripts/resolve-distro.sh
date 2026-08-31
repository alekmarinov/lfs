#!/bin/bash
# Resolves a DISTRO argument to the directory it names, and prints it.
#
#   resolve-distro.sh minimal              -> <base>/distros/minimal
#   resolve-distro.sh -i minimal           -> minimal          (its ID)
#   resolve-distro.sh -o minimal           -> build/minimal    (its output dir)
#
# The output directory is where the rootfs and the image are written. It is
# named after the ID rather than the directory, so two distros cannot collide
# by both living in a directory called 'image'. $OUT overrides it, and a client
# building its own distro is expected to: an output directory named after
# somebody else's distro has no business inside this repository.
#
# A distro is either one of ours, named, or anyone's, given as a path.
# Anything containing a '/' is a path and is used as given, resolved against
# the working directory; a bare name is looked up under distros/. That is the
# whole of "lfs builds a distro it does not contain": one directory, named
# from outside.
#
# It lives in its own script because build-distro.sh and
# build-distro-packages.sh both have to agree about it, and two copies of a
# resolution rule are two rules.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/.." &> /dev/null && pwd )

mode=dir
case "$1" in
    -i) mode=id;  shift ;;
    -o) mode=out; shift ;;
esac

distro=$1
if [ "$distro" == "" ]; then
    echo "Missing expected argument distro" >&2
    exit 1
fi

case "$distro" in
    */*) DISTRO_DIR=$( cd -- "${distro%/}" 2>/dev/null && pwd ) \
             || { echo "No such distro directory: ${distro%/}" >&2; exit 1; } ;;
    *)   DISTRO_DIR="$BASE_DIR/distros/$distro" ;;
esac

[ -d "$DISTRO_DIR" ] || { echo "Unknown distro '$distro', expected $DISTRO_DIR" >&2; exit 1; }
[ -f "$DISTRO_DIR/distro.conf" ] || { echo "Missing $DISTRO_DIR/distro.conf" >&2; exit 1; }

# read rather than sourced: distro.conf is configuration, and sourcing it here
# would let it set anything in whatever called this.
distro_id() {
    sed -n 's/^ID=\"\(.*\)\"$/\1/p; s/^ID=\([^\"]*\)$/\1/p' "$DISTRO_DIR/distro.conf" | tail -1
}

case "$mode" in
    dir) echo "$DISTRO_DIR" ;;
    id|out)
        ID=$(distro_id)
        case "$ID" in
            "")                echo "$DISTRO_DIR/distro.conf sets no ID" >&2; exit 1 ;;
            *[!a-zA-Z0-9._-]*) echo "ID '$ID' is not usable as a directory name" >&2; exit 1 ;;
        esac
        if [ "$mode" = id ]; then echo "$ID"; else echo "${OUT:-build/$ID}"; fi
        ;;
esac

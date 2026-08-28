#!/bin/bash
# Prints every package the build produces, in build order, minus the ones
# marked '# BUILD_ONLY:' in their build script.
#
# A build only package is scaffolding - rust, nasm, cbindgen - which exists to
# compile something else and would never be run on a finished system. They have
# to be excluded explicitly: the build order is the only complete list of what
# gets built, and reading it as 'everything a distro should install' is how
# 700 MB of rust ends up in an image.
set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

grep -h -l "^# BUILD_ONLY:" scripts/packages/*/*.sh 2>/dev/null \
    | xargs -r -n1 basename | sed 's/\.sh$//' | sort -u > /tmp/.build_only.$$

grep -vE '^[[:space:]]*#' scripts/packages/build-packages.sh \
    | grep -oE '/scripts/packages/(lfs|blfs)/[^ ]+\.sh' \
    | sed 's|.*/||; s|\.sh$||' \
    | nl -ba | tac | awk '!seen[$2]++' | tac | awk '{print $2}' \
    | grep -vxF -f /tmp/.build_only.$$ \
    | sed 's/$/.tar.gz/'
rm -f /tmp/.build_only.$$

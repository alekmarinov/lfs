#!/bin/bash
# Installs package in rootfs
# example: install-package.sh 9.2-make-lfs-bootscripts.tar.gz
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PACKAGES="packages"
ROOTFS="rootfs"
TMP="tmp"
package="$1"

if [ "$package" == "" ]; then
    echo "Missing argument: package"
    exit 1
fi

tmpdir="$TMP/${package%.*.*}"
rm -rfv "$tmpdir"
mkdir "$tmpdir"
tar xvf "$PACKAGES/$package" -C "$tmpdir"
$SCRIPT_DIR/copy-or-del.sh "$tmpdir" "$ROOTFS"
rm -rf "$tmpdir"

#!/bin/bash
set -e
echo "Building BLFS-fribidi.."

# fribidi
# Implements the unicode bidirectional algorithm - the rules for laying out
# text which runs right to left. pango requires it.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/fribidi.html
#
# BUILD_REQUIRES: 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/fribidi
tar -xf /sources/fribidi-*.tar.xz -C /tmp/
mv /tmp/fribidi-* /tmp/fribidi
pushd /tmp/fribidi
mkdir build
pushd build
meson --prefix=/usr --buildtype=release ..
ninja
ninja install
popd
popd
rm -rf /tmp/fribidi

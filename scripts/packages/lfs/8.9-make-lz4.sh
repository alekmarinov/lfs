#!/bin/bash
set -e
echo "Building lz4.."

# 8.9. lz4
# A fast compression library. New in 12.4; udev and others link it.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/lz4.html
#
# BUILD_REQUIRES: 8.69-make-make
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/lz4
tar -xf /sources/lz4-*.tar.gz -C /tmp/
mv /tmp/lz4-* /tmp/lz4
pushd /tmp/lz4
make BUILD_STATIC=no PREFIX=/usr
make BUILD_STATIC=no PREFIX=/usr install
popd
rm -rf /tmp/lz4

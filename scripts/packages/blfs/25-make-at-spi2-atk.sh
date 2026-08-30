#!/bin/bash
set -e
echo "Building BLFS-at-spi2-atk.."

# at-spi2-atk
# Bridges the atk interfaces to the at-spi2 service. gtk requires it.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/at-spi2-atk.html
#
# BUILD_REQUIRES: 25-make-atk 25-make-at-spi2-core 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/at-spi2-atk
tar -xf /sources/at-spi2-atk-*.tar.xz -C /tmp/
mv /tmp/at-spi2-atk-* /tmp/at-spi2-atk
pushd /tmp/at-spi2-atk
mkdir build
pushd build
meson --prefix=/usr --buildtype=release ..
ninja
ninja install
popd
popd
rm -rf /tmp/at-spi2-atk

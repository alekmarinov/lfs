#!/bin/bash
# PACKAGE:  at-spi2-core
# SOURCE:   at-spi2-core-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-at-spi2-core.."

# at-spi2-core
# The service side of accessibility, which talks over dbus.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/at-spi2-core.html
#
# BUILD_REQUIRES: 9-make-glib 12-make-dbus 9-make-libxml2 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/at-spi2-core
tar -xf /sources/at-spi2-core-*.tar.xz -C /tmp/
mv /tmp/at-spi2-core-* /tmp/at-spi2-core
pushd /tmp/at-spi2-core
mkdir build
pushd build
meson --prefix=/usr --buildtype=release -Dintrospection=no ..
ninja
ninja install
popd
popd
rm -rf /tmp/at-spi2-core

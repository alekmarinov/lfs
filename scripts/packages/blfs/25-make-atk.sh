#!/bin/bash
# PACKAGE:  atk
# SOURCE:   atk-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-atk.."

# atk
# The accessibility toolkit interfaces. gtk implements them whether or not
# anything uses them, so it is required rather than optional.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/atk.html
#
# BUILD_REQUIRES: 9-make-glib 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/atk
tar -xf /sources/atk-*.tar.xz -C /tmp/
mv /tmp/atk-* /tmp/atk
pushd /tmp/atk
mkdir build
pushd build
meson --prefix=/usr --buildtype=release -Dintrospection=false ..
ninja
ninja install
popd
popd
rm -rf /tmp/atk

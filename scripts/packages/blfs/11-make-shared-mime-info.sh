#!/bin/bash
set -e
echo "Building BLFS-shared-mime-info.."

# shared-mime-info
# The mime type database. gdk-pixbuf uses it to work out what an image file
# is, and gtk to pick an icon for it.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/shared-mime-info.html
#
# BUILD_REQUIRES: 9-make-glib 9-make-libxml2 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/shared-mime-info
tar -xf /sources/shared-mime-info-*.tar.bz2 -C /tmp/
mv /tmp/shared-mime-info-* /tmp/shared-mime-info
pushd /tmp/shared-mime-info
mkdir build
pushd build
meson --prefix=/usr --buildtype=release -Dupdate-mimedb=true ..
ninja
ninja install
popd
popd
rm -rf /tmp/shared-mime-info

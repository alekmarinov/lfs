#!/bin/bash
set -e
echo "Building BLFS-gdk-pixbuf.."

# gdk-pixbuf
# Loads images into memory for gtk to draw. The loaders it builds are the
# reason libjpeg-turbo, libpng and libtiff come before it.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/gdk-pixbuf.html
#
# BUILD_REQUIRES: 9-make-glib 10-make-libjpeg-turbo 10-make-libpng 10-make-libtiff 9-make-shared-mime-info 8.53-make-meson 8.52-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/gdk-pixbuf
tar -xf /sources/gdk-pixbuf-*.tar.xz -C /tmp/
mv /tmp/gdk-pixbuf-* /tmp/gdk-pixbuf
pushd /tmp/gdk-pixbuf
mkdir build
pushd build
meson --prefix=/usr \
      --buildtype=release \
      -Dintrospection=disabled \
      -Dman=false \
      -Dinstalled_tests=false \
      ..
ninja
ninja install
popd
popd
rm -rf /tmp/gdk-pixbuf

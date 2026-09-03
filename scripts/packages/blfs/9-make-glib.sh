#!/bin/bash
# PACKAGE:  glib
# SOURCE:   glib-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-glib.."

# glib
# The GNOME base library. Everything above it in the gtk stack needs it, so it
# is the first real step towards a browser.
#
# NOTE glib has no introspection option - it builds the bindings only when
# gobject-introspection is installed, and it is not. The packages above it in
# the stack do have such an option, and it is turned off there, so nothing
# pulls gobject-introspection in.
#
# BUILD_REQUIRES: 9-make-pcre 8.50-make-libffi 7.10-make-python 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.


rm -rf /tmp/glib
tar -xf /sources/glib-*.tar.xz -C /tmp/
mv /tmp/glib-* /tmp/glib
pushd /tmp/glib
mkdir build
pushd build
meson --prefix=/usr \
      --buildtype=release \
      -Dman=false \
      -Dtests=false \
      ..
ninja
ninja install
popd
popd
rm -rf /tmp/glib

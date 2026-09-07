#!/bin/bash
# PACKAGE:  libnotify
# SOURCE:   libnotify-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libnotify.."

# libnotify
# The desktop notification library. Firefox 140 lists it as a required
# dependency; Firefox 102 did not, which is why it was not here before.
# https://www.linuxfromscratch.org/blfs/view/12.4/x/libnotify.html
#
# NOTE -D gtk_doc=false and -D man=false. Both need docbook tooling and neither
# ships anything a running system uses.
#
# NOTE -D introspection=disabled. Unlike most such options this one is a
# feature defaulting to 'enabled', not 'auto', so it does not quietly skip
# itself when the tooling is absent - it stops with
#   ERROR: Program 'g-ir-scanner' not found or not executable
# There is no gobject-introspection in this tree, and nothing here consumes
# GIR typelibs.
#
# BUILD_REQUIRES: 25-make-gdk-pixbuf 9-make-glib
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/libnotify
tar -xf /sources/libnotify-*.tar.xz -C /tmp/
mv /tmp/libnotify-* /tmp/libnotify
pushd /tmp/libnotify
mkdir build
cd build
meson setup --prefix=/usr \
    --buildtype=release \
    -D gtk_doc=false \
    -D man=false \
    -D introspection=disabled \
    ..
ninja
ninja install
popd
rm -rf /tmp/libnotify

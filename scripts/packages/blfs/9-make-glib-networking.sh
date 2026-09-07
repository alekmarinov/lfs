#!/bin/bash
# PACKAGE:  glib-networking
# SOURCE:   glib-networking-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-glib-networking.."

# glib-networking
# The TLS backend GIO loads at runtime. Without it every https:// request
# through libsoup fails with "TLS support is not available", which is a
# confusing way to discover a missing package.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/glib-networking.html
#
# BUILD_REQUIRES: 9-make-glib 4-make-gnutls 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE both proxy backends are disabled. They are meson 'feature' options
# defaulting to 'enabled', so they do not skip themselves when their
# dependencies are absent - they stop the configure:
#   libproxy      wants the libproxy package
#   gnome_proxy   wants gsettings-desktop-schemas, which drags in a GNOME
#                 desktop's settings machinery to read a proxy setting
# An appliance browser talks to the network directly. TLS still works: that
# is the gnutls backend, which is what this package is really here for.

rm -rf /tmp/glib-networking
tar -xf /sources/glib-networking-*.tar.xz -C /tmp/
mv /tmp/glib-networking-* /tmp/glib-networking
pushd /tmp/glib-networking
mkdir build
cd build
meson setup \
   --prefix=/usr \
   --buildtype=release \
   -D libproxy=disabled \
   -D gnome_proxy=disabled \
   ..
ninja
ninja install
popd
rm -rf /tmp/glib-networking

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
# NOTE introspection=disabled, not 'no'. This is a meson 'feature' option and
# takes enabled/disabled/auto only:
#   ERROR: Value "no" (of type "string") for option "introspection" is not one
#   of the choices.
# 'disabled' rather than the book's implicit 'auto' because there is no
# gobject-introspection here for auto to find.
#
# NOTE gtk2_atk_adaptor=false, which the book also passes. It is a boolean
# defaulting to true, and it builds a module loaded by GTK2 - which this tree
# does not have at all.
#
# NOTE systemd_user_dir=/tmp keeps the systemd user service out of the
# package. There is no systemd here, and without this it installs into a
# directory nothing reads.
meson setup --prefix=/usr \
    --buildtype=release \
    -D introspection=disabled \
    -D gtk2_atk_adaptor=false \
    -D systemd_user_dir=/tmp \
    ..
ninja
ninja install
popd
popd
rm -rf /tmp/at-spi2-core

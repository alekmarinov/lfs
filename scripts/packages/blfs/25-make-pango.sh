#!/bin/bash
set -e
echo "Building BLFS-pango.."

# pango
# Lays out and renders text. This is what turns a string plus a font into
# glyphs in the right places, including for scripts which do not run left to
# right, which is why fribidi and harfbuzz come first.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/pango.html
#
# BUILD_REQUIRES: 9-make-glib 25-make-cairo 10-make-fribidi 10-make-harfbuzz 10-make-fontconfig 24-make-xorg-libraries 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/pango
tar -xf /sources/pango-*.tar.xz -C /tmp/
mv /tmp/pango-* /tmp/pango
pushd /tmp/pango
mkdir build
pushd build
meson --prefix=/usr \
      --buildtype=release \
      -Dintrospection=disabled \
      ..
ninja
ninja install
popd
popd
rm -rf /tmp/pango

#!/bin/bash
# PACKAGE:  cairo
# SOURCE:   cairo-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-cairo.."

# cairo
# The 2D drawing library everything above it renders through: pango draws text
# with it, gtk draws widgets with it.
# https://www.linuxfromscratch.org/blfs/view/12.4/x/cairo.html
#
# NOTE cairo 1.18 builds with meson; the autotools build was removed upstream.
# That retires a long-standing problem here rather than porting it: the old
# recipe passed --enable-trace=no, --enable-interpreter=no and
# --enable-symbol-lookup=no, and then deleted cairo-sphinx afterwards, because
# those three debugging tools linked libbfd and lzo and so made binutils a
# runtime dependency of anything that draws. The meson build does not build
# them at all, so the flags and the cleanup are both gone.
#
# NOTE the -std=gnu17 workaround is also gone with them - it was for the pdiff
# helper, part of the same removed test tooling, which typedefed its own bool.
#
# BUILD_REQUIRES: 9-make-glib 10-make-fontconfig 10-make-freetype 10-make-libpng 10-make-pixman 24-make-xorg-libraries 24-make-mesa
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/cairo
tar -xf /sources/cairo-*.tar.xz -C /tmp/
mv /tmp/cairo-* /tmp/cairo
pushd /tmp/cairo
mkdir build
cd build
meson setup --prefix=/usr --buildtype=release ..
ninja
if [ $LFS_TEST -eq 1 ]; then ninja test || true; fi
ninja install
popd
rm -rf /tmp/cairo

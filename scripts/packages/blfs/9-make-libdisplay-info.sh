#!/bin/bash
# PACKAGE:  libdisplay-info
# SOURCE:   libdisplay-info-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libdisplay-info.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 15 MB"

# libdisplay-info
# Parses EDID, the block a monitor uses to describe itself. weston needs it to
# know what a display can do rather than guessing, and pins it to a range:
# '>= 0.2.0, < 0.4.0'.
#
# It arrived here as a meson wrap - weston would have downloaded it mid-build,
# which the chroot has no network for and which would put an unpinned
# dependency in a package. Better as a package of its own.
#
# https://gitlab.freedesktop.org/emersion/libdisplay-info
#
# BUILD_REQUIRES: 9-make-hwdata 8.51-make-python 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE hwdata is 'required: false' upstream, and without it the build falls
# back to reading /usr/share/hwdata/pnp.ids directly - which fails at
# configure time if nothing installed it. Declared as a build dependency here
# so the order cannot put them the wrong way round.

rm -rf /tmp/libdisplay-info
tar -xf /sources/libdisplay-info-*.tar.xz -C /tmp/
mv /tmp/libdisplay-info-[0-9]* /tmp/libdisplay-info
pushd /tmp/libdisplay-info
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      --wrap-mode=nodownload
ninja
ninja install
popd
rm -rf /tmp/libdisplay-info

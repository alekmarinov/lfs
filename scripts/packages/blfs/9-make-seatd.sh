#!/bin/bash
# PACKAGE:  seatd
# SOURCE:   seatd-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-seatd.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 5 MB"

# seatd
# Provides libseat, which weston links to be granted the DRM device and the
# input devices. This system has neither logind nor a session manager, so the
# question "who is allowed to open /dev/dri/card0" has had no answer beyond
# "whoever is root".
#
# https://git.sr.ht/~kennylevinsen/seatd
#
# BUILD_REQUIRES: 8.57-make-meson 8.56-make-ninja 8.76-make-udev
# RUNTIME_REQUIRES:
#
# NOTE the builtin backend, and no daemon. libseat can talk to logind, to a
# seatd daemon, or open the devices itself when the caller is already root.
# The last is what fits here: the browser session runs as root because nothing
# else hands out the display, so a daemon would be a process whose only job is
# to grant permission that is already held.
#
# server=disabled for the same reason - it would build the daemon we are not
# going to run.

rm -rf /tmp/seatd
tar -xf /sources/seatd-*.tar.gz -C /tmp/
mv /tmp/seatd-[0-9]* /tmp/seatd
pushd /tmp/seatd
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      -Dlibseat-builtin=enabled \
      -Dlibseat-seatd=enabled \
      -Dlibseat-logind=disabled \
      -Dserver=disabled \
      -Dexamples=disabled \
      -Dman-pages=disabled
ninja
ninja install
popd
rm -rf /tmp/seatd

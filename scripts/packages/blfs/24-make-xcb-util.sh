#!/bin/bash
# PACKAGE:  xcb-util
# SOURCE:   xcb-util-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-xcb-util.."

# xcb-util
# Convenience helpers over raw libxcb: xcb-aux, xcb-atom, xcb-event.
#
# Here because startup-notification requires it - its configure stops with
# "Cannot find xcb-aux" - and startup-notification is required by firefox 140.
# Nothing in the 11.2 tree needed either, which is why neither was present.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/x/xcb-util.html
#
# BUILD_REQUIRES: 24-make-libxcb 24-make-xorg-libraries
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/xcb-util
tar -xf /sources/xcb-util-*.tar.xz -C /tmp/
mv /tmp/xcb-util-* /tmp/xcb-util
pushd /tmp/xcb-util
./configure $XORG_CONFIG
make
make install
popd
rm -rf /tmp/xcb-util

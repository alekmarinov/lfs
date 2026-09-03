#!/bin/bash
# PACKAGE:  libepoxy
# SOURCE:   libepoxy-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libepoxy.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 15 MB"

# 24. libepoxy
# Resolves OpenGL function pointers at run time, so a program does not have to
# know which GL implementation it is talking to. The X server needs it for
# glamor, which is the acceleration path this build has been without, and gtk3
# requires it outright - it is the reason a browser cannot be built before
# Mesa.
#
# required: mesa
# https://www.linuxfromscratch.org/blfs/view/11.2/x/libepoxy.html
#
# BUILD_REQUIRES: 24-make-mesa 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/libepoxy
tar -xf /sources/libepoxy-*.tar.xz -C /tmp/
mv /tmp/libepoxy-* /tmp/libepoxy
pushd /tmp/libepoxy

mkdir build
pushd build
meson --prefix=$XORG_PREFIX --buildtype=release ..
ninja
ninja install

popd
popd
rm -rf /tmp/libepoxy

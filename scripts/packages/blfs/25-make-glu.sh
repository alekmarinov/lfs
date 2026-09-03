#!/bin/bash
# PACKAGE:  glu
# SOURCE:   glu-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-glu.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 10 MB"

# 24. glu
# The OpenGL utility library. It used to be part of Mesa and was split out, so
# a program written against the old API - mesa-demos among them - does not
# build without it.
#
# required: mesa
# https://www.linuxfromscratch.org/blfs/view/11.2/x/glu.html
#
# BUILD_REQUIRES: 24-make-mesa
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/glu
tar -xf /sources/glu-*.tar.xz -C /tmp/
mv /tmp/glu-* /tmp/glu
pushd /tmp/glu

./configure --prefix=$XORG_PREFIX --disable-static
make
make install

popd
rm -rf /tmp/glu

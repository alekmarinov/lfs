#!/bin/bash
set -e
echo "Building BLFS-alsa-lib.."

# alsa-lib
# The ALSA library. Firefox needs an audio backend to build against; alsa is
# the one already in the kernel, and it avoids pulling in pulseaudio and the
# daemon that goes with it.
# https://www.linuxfromscratch.org/blfs/view/11.2/multimedia/alsa-lib.html
#
# BUILD_REQUIRES: 8.69-make-make
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/alsa-lib
tar -xf /sources/alsa-lib-*.tar.bz2 -C /tmp/
mv /tmp/alsa-lib-* /tmp/alsa-lib
pushd /tmp/alsa-lib
./configure --prefix=/usr --disable-static
make
make install
popd
rm -rf /tmp/alsa-lib

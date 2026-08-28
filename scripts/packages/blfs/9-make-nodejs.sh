#!/bin/bash
set -e
echo "Building BLFS-nodejs.."

# nodejs
# Firefox runs javascript at build time to generate parts of itself, so node
# is required to compile it. Build only - it is in no distro.
#
# openssl and zlib are taken from the system rather than the copies bundled in
# the node source, which are another two libraries to keep patched otherwise.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/nodejs.html
#
# BUILD_REQUIRES: 7.10-make-python 8.26-make-gcc 8.65-make-make
# RUNTIME_REQUIRES:
# BUILD_ONLY: firefox runs javascript at build time to generate sources; nothing here runs node
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/nodejs
tar -xf /sources/node-v*.tar.xz -C /tmp/
mv /tmp/node-v* /tmp/nodejs
pushd /tmp/nodejs
./configure --prefix=/usr --shared-openssl --shared-zlib
make
make install
popd
rm -rf /tmp/nodejs

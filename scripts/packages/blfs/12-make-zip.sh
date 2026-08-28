#!/bin/bash
set -e
echo "Building BLFS-zip.."

# zip
# Info-ZIP. Firefox packages parts of itself into zip archives during the
# build and will not configure without it. unzip was already here, zip was not.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/zip.html
#
# BUILD_REQUIRES: 8.65-make-make
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/zip
tar -xf /sources/zip30.tar.gz -C /tmp/
mv /tmp/zip30 /tmp/zip
pushd /tmp/zip
make -f unix/Makefile generic_gcc
make -f unix/Makefile prefix=/usr MANDIR=/usr/share/man/man1 install
popd
rm -rf /tmp/zip

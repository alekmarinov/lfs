#!/bin/bash
set -e
echo "Building BLFS-zip.."

# zip
# Info-ZIP. Firefox packages parts of itself into zip archives during the
# build and will not configure without it. unzip was already here, zip was not.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/zip.html
#
# NOTE 'generic' is called directly with the compiler set, which is what
# generic_gcc does except that it hardcodes CC=gcc and so discards the
# settings below. They are needed because the 'flags' probe compiles
# old-style programs: GCC 14 made those diagnostics errors, the probe then
# concludes there is no memset, defines ZMEM, and zip's own declarations of
# memset, memcpy and memcmp conflict with string.h.
#
# BUILD_REQUIRES: 8.69-make-make
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/zip
tar -xf /sources/zip30.tar.gz -C /tmp/
mv /tmp/zip30 /tmp/zip
pushd /tmp/zip
make -f unix/Makefile generic \
    CC='gcc -std=gnu17 -Wno-error=implicit-int -Wno-error=implicit-function-declaration' \
    CPP='gcc -E'
make -f unix/Makefile prefix=/usr MANDIR=/usr/share/man/man1 install
popd
rm -rf /tmp/zip

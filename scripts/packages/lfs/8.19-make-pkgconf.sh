#!/bin/bash
# PACKAGE:  pkgconf
# SOURCE:   pkgconf-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building pkgconf.."

# 8.19. pkgconf
# Replaces pkg-config, which 12.4 dropped. The two symlinks keep every
# configure script which looks for pkg-config working.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/pkgconf.html
#
# BUILD_REQUIRES: 8.69-make-make
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/pkgconf
tar -xf /sources/pkgconf-*.tar.xz -C /tmp/
mv /tmp/pkgconf-* /tmp/pkgconf
pushd /tmp/pkgconf
VER=$(basename /sources/pkgconf-*.tar.xz .tar.xz | sed "s/pkgconf-//")
./configure --prefix=/usr \
    --disable-static \
    --docdir=/usr/share/doc/pkgconf-$VER
make
make install
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
popd
rm -rf /tmp/pkgconf

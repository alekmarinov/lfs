#!/bin/bash
# PACKAGE:  pcre2
# SOURCE:   pcre2-*.tar.bz2
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-pcre2.."

# pcre2
# Perl compatible regular expressions, second generation.
#
# NOTE this replaces pcre 8.45, which BLFS 12.4 no longer carries. The reason
# pcre 8 was kept before is gone: glib moved to pcre2 in 2.74, and the glib
# here is 2.84. Building glib against a tree with pcre 8 and no pcre2 made
# meson download its own copy of pcre mid build, which fails without network -
# that is what the old pcre recipe's note was about, and it now argues the
# other way round.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/pcre2.html
#
# BUILD_REQUIRES: 8.6-make-zlib 8.7-make-bzip2 8.12-make-readline
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

VER=$(ls /sources/pcre2-*.tar.bz2 | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
rm -rf /tmp/pcre2
tar -xf /sources/pcre2-*.tar.bz2 -C /tmp/
mv /tmp/pcre2-* /tmp/pcre2
pushd /tmp/pcre2
./configure --prefix=/usr \
    --docdir=/usr/share/doc/pcre2-$VER \
    --enable-unicode \
    --enable-jit \
    --enable-pcre2-16 \
    --enable-pcre2-32 \
    --enable-pcre2grep-libz \
    --enable-pcre2grep-libbz2 \
    --enable-pcre2test-libreadline \
    --disable-static
make
make install
popd
rm -rf /tmp/pcre2

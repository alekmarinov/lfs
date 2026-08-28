#!/bin/bash
set -e
echo "Building BLFS-pcre.."

# pcre
# Perl compatible regular expressions, the original library.
#
# NOTE this is pcre, not pcre2, and both are here on purpose. glib 2.72 links
# against pcre 8: it only moved to pcre2 in 2.74. Building pcre2 and expecting
# glib to use it makes meson fall back to downloading its own copy of pcre 8.37
# mid build, which fails because the build has no network.
#
# https://www.linuxfromscratch.org/blfs/view/11.2/general/pcre.html
#
# BUILD_REQUIRES: 8.6-make-zlib 8.7-make-bzip2 8.11-make-readline
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/pcre
tar -xf /sources/pcre-8*.tar.bz2 -C /tmp/
mv /tmp/pcre-8* /tmp/pcre
pushd /tmp/pcre
./configure --prefix=/usr \
    --docdir=/usr/share/doc/pcre-8.45 \
    --enable-unicode-properties \
    --enable-pcre16 \
    --enable-pcre32 \
    --enable-pcregrep-libz \
    --enable-pcregrep-libbz2 \
    --enable-pcretest-libreadline \
    --disable-static
make
make install
popd
rm -rf /tmp/pcre

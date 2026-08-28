#!/bin/bash
set -e
echo "Building BLFS-pcre2.."

# pcre2
# Perl compatible regular expressions, version 2. glib requires it.
#
# BUILD_REQUIRES: 8.6-make-zlib 8.7-make-bzip2 8.11-make-readline
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.


rm -rf /tmp/pcre2
tar -xf /sources/pcre2-*.tar.bz2 -C /tmp/
mv /tmp/pcre2-* /tmp/pcre2
pushd /tmp/pcre2
./configure --prefix=/usr \
    --docdir=/usr/share/doc/pcre2-10.40 \
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

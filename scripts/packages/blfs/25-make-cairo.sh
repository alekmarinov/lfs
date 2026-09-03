#!/bin/bash
# PACKAGE:  cairo
# SOURCE:   cairo-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-cairo.."

# cairo
# The 2D drawing library everything above it renders through: pango draws text
# with it, gtk draws widgets with it.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/cairo.html
#
# NOTE -std=gnu17. cairo's pdiff helper typedefs its own 'bool', which C23
# turned into a keyword.
#
# BUILD_REQUIRES: 9-make-glib 10-make-fontconfig 10-make-freetype 10-make-libpng 10-make-pixman 24-make-xorg-libraries 24-make-mesa
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/cairo
tar -xf /sources/cairo-*.tar.xz -C /tmp/
mv /tmp/cairo-* /tmp/cairo
pushd /tmp/cairo

# NOTE --enable-trace=no. cairo-trace is a debugging tool which records the
# drawing calls a program makes. It links libbfd to turn addresses back into
# symbol names, which makes the whole of binutils a runtime dependency of
# anything that installs cairo - and it drags lzo in behind it. It also does
# not compile any more: it casts through PTR, a typedef binutils dropped from
# bfd.h in 2.34. Nothing here uses it, so it is left out rather than patched.
#
# --enable-interpreter=no for the same reason: the script interpreter and
# cairo-sphinx are debugging tools and they link lzo, which would otherwise
# have to be installed in every image that draws anything.
#
# --enable-symbol-lookup=no stops cairo-sphinx being built, the last of the
# three and the other half of the lzo dependency.
CC='gcc -std=gnu17' ./configure --prefix=/usr \
    --disable-static \
    --enable-tee \
    --enable-trace=no \
    --enable-interpreter=no \
    --enable-symbol-lookup=no
make
make install

# cairo-sphinx is a benchmarking harness. --enable-symbol-lookup=no does not
# stop it being built, and it is the last thing linking lzo, so it is removed
# after the install rather than dragging lzo into every image which draws.
rm -fv /usr/bin/cairo-sphinx
rm -fv /usr/lib/cairo/cairo-sphinx.*

popd
rm -rf /tmp/cairo

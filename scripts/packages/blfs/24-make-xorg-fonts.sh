#!/bin/bash
# PACKAGE:  xorg-fonts
# VERSION:  11.2
# RELEASE:  1
# GROUP:    xorg
# CLASS:    extra
set -e
echo "Building BLFS-Xorg fonts.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 8 MB"

# 24. Xorg Fonts
# The book builds these as one page. font-util is the one the Xorg server
# requires, the rest are the fonts the default configuration expects.
# https://www.linuxfromscratch.org/blfs/view/12.4/x/x7font.html

. /etc/profile.d/xorg.sh

PACKAGES="
font-util-1.4.1.tar.xz
encodings-1.1.0.tar.xz
font-alias-1.0.5.tar.xz
font-adobe-utopia-type1-1.0.5.tar.xz
font-bh-ttf-1.0.4.tar.xz
font-bh-type1-1.0.4.tar.xz
font-ibm-type1-1.0.4.tar.xz
font-misc-ethiopic-1.0.5.tar.xz
font-xfree86-type1-1.0.5.tar.xz
"

# The X sources are old C: they name variables 'true' and use the empty
# parameter list to mean 'unspecified'. Both changed meaning in C23, which GCC
# 15 defaults to, so the whole set is built against the standard it was written
# for rather than patching each package in turn.
export CC='gcc -std=gnu17'

for package in $PACKAGES; do
    packagedir=${package%.tar.?z*}
    echo "=== $packagedir ==="
    rm -rf "/tmp/$packagedir"
    tar -xf "/sources/$package" -C /tmp/
    pushd "/tmp/$packagedir"
    ./configure $XORG_CONFIG
    make
    make install
    popd
    rm -rf "/tmp/$packagedir"
done

# so that fontconfig finds the X11 fonts through its default search path
install -v -d -m755 /usr/share/fonts
ln -svfn $XORG_PREFIX/share/fonts/X11/OTF /usr/share/fonts/X11-OTF
ln -svfn $XORG_PREFIX/share/fonts/X11/TTF /usr/share/fonts/X11-TTF

#!/bin/bash
set -e
echo "Building BLFS-Xorg applications.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 30 MB"

# 24. Xorg Applications
#
# The subset of the book's page which a session needs: the server compiles its
# keymaps with xkbcomp, startx authorises the display with xauth and iceauth
# and loads resources with xrdb, and the rest are the tools to inspect and
# configure a running server.
#
# NOTE the remaining applications of the page - xdriinfo among them - need
# Mesa, which is not installed yet.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/x7app.html

. /etc/profile.d/xorg.sh

PACKAGES="
iceauth-1.0.9.tar.xz
mkfontscale-1.2.2.tar.xz
setxkbmap-1.3.3.tar.xz
xauth-1.1.2.tar.xz
xcursorgen-1.0.7.tar.bz2
xdpyinfo-1.3.3.tar.xz
xev-1.2.5.tar.xz
xkbcomp-1.4.5.tar.bz2
xmodmap-1.0.11.tar.xz
xprop-1.2.5.tar.bz2
xrandr-1.5.1.tar.xz
xrdb-1.2.1.tar.bz2
xset-1.2.4.tar.bz2
xsetroot-1.1.2.tar.bz2
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

echo "Installed $(echo $PACKAGES | wc -w) Xorg applications"

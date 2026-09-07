#!/bin/bash
# PACKAGE:  xorg-apps
# VERSION:  11.2
# RELEASE:  1
# GROUP:    xorg
# CLASS:    extra
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
# https://www.linuxfromscratch.org/blfs/view/12.4/x/x7app.html

. /etc/profile.d/xorg.sh

PACKAGES="
iceauth-1.0.10.tar.xz
mkfontscale-1.2.3.tar.xz
sessreg-1.1.4.tar.xz
setxkbmap-1.3.4.tar.xz
smproxy-1.0.8.tar.xz
xauth-1.1.4.tar.xz
xcmsdb-1.0.7.tar.xz
xcursorgen-1.0.9.tar.xz
xdpyinfo-1.4.0.tar.xz
xdriinfo-1.0.8.tar.xz
xev-1.2.6.tar.xz
xgamma-1.0.8.tar.xz
xhost-1.0.10.tar.xz
xinput-1.6.4.tar.xz
xkbcomp-1.4.7.tar.xz
xkbevd-1.1.6.tar.xz
xkbutils-1.0.6.tar.xz
xkill-1.0.6.tar.xz
xlsatoms-1.1.4.tar.xz
xlsclients-1.1.5.tar.xz
xmessage-1.0.7.tar.xz
xmodmap-1.0.11.tar.xz
xpr-1.2.0.tar.xz
xprop-1.2.8.tar.xz
xrandr-1.5.3.tar.xz
xrdb-1.2.2.tar.xz
xrefresh-1.1.0.tar.xz
xset-1.2.5.tar.xz
xsetroot-1.1.3.tar.xz
xvinfo-1.1.5.tar.xz
xwd-1.0.9.tar.xz
xwininfo-1.1.6.tar.xz
xwud-1.0.7.tar.xz
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

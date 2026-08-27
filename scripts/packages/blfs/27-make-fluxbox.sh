#!/bin/bash
set -e
echo "Building BLFS-Fluxbox.."
echo "Approximate build time: 0.5 SBU"
echo "Required disk space: 70 MB"

# 27. Fluxbox
# A window manager with decorations, an application menu, a toolbar and
# workspaces - what twm, the reference window manager, does not have.
# required: a graphical environment
# recommended: dbus (runtime)
# https://www.linuxfromscratch.org/blfs/view/11.2/x/fluxbox.html
#
# NOTE the commands are not chained with &&: a failing && chain does not trip
# 'set -e', so the commands after it would run as if the build had succeeded.

. /etc/profile.d/xorg.sh

rm -rf /tmp/fluxbox
tar -xf /sources/fluxbox-*.tar.xz -C /tmp/
mv /tmp/fluxbox-* /tmp/fluxbox
pushd /tmp/fluxbox

# works around a build failure with gcc 11 and later
sed -i '/text_prop.value > 0/s/>/!=/' util/fluxbox-remote.cc

./configure --prefix=/usr
make
make install
popd
rm -rf /tmp/fluxbox

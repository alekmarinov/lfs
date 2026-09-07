#!/bin/bash
# PACKAGE:  startup-notification
# SOURCE:   startup-notification-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-startup-notification.."

# startup-notification
# Lets a launcher show that an application is starting before its first window
# maps. Firefox 140 lists it as required.
# https://www.linuxfromscratch.org/blfs/view/12.4/x/startup-notification.html
#
# BUILD_REQUIRES: 24-make-xcb-util 24-make-xorg-libraries
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/startup-notification
tar -xf /sources/startup-notification-*.tar.gz -C /tmp/
mv /tmp/startup-notification-* /tmp/startup-notification
pushd /tmp/startup-notification
./configure --prefix=/usr --disable-static
make
make install
popd
rm -rf /tmp/startup-notification

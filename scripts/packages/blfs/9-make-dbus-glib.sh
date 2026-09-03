#!/bin/bash
# PACKAGE:  dbus-glib
# SOURCE:   dbus-glib-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-dbus-glib.."

# dbus-glib
# The older glib bindings for dbus. glib has its own dbus support now, but
# firefox still asks for this one at configure time and stops without it.
#
# https://www.linuxfromscratch.org/blfs/view/11.2/general/dbus-glib.html
#
# NOTE -std=gnu17. dbus-glib uses 'bool' as an ordinary identifier, which C23
# turned into a keyword.
#
# BUILD_REQUIRES: 12-make-dbus 9-make-glib 9-make-libxml2
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/dbus-glib
tar -xf /sources/dbus-glib-*.tar.gz -C /tmp/
mv /tmp/dbus-glib-* /tmp/dbus-glib
pushd /tmp/dbus-glib
CC='gcc -std=gnu17' ./configure --prefix=/usr --sysconfdir=/etc --disable-static
make
make install
popd
rm -rf /tmp/dbus-glib

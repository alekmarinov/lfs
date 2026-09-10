#!/bin/bash
# PACKAGE:  hwdata
# SOURCE:   hwdata-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-hwdata.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 30 MB"

# hwdata
# Data, not code: the tables that turn hardware identifiers into names. Here
# for one file, pnp.ids, which libdisplay-info compiles into a lookup table so
# a monitor's EDID can name its manufacturer.
#
# https://github.com/vcrhonek/hwdata
#
# BUILD_REQUIRES: 8.69-make-make
# RUNTIME_REQUIRES:
#
# NOTE --datadir=/usr/share and not /usr/share/hwdata. Its configure is hand
# written, not autoconf, and appends its own name to whatever it is given -
# so the obvious-looking value installs pnp.ids to
# /usr/share/hwdata/hwdata/pnp.ids and hides hwdata.pc under
# /usr/share/hwdata/pkgconfig where nothing searches. libdisplay-info then
# reports "File /usr/share/hwdata/pnp.ids does not exist", which is true and
# says nothing about why.

rm -rf /tmp/hwdata
tar -xf /sources/hwdata-*.tar.gz -C /tmp/
mv /tmp/hwdata-[0-9]* /tmp/hwdata
pushd /tmp/hwdata
./configure --prefix=/usr --datadir=/usr/share
make install
# The one file libdisplay-info opens by absolute path, and the one that says
# pkg-config can find the rest.
[ -f /usr/share/hwdata/pnp.ids ] || { echo "pnp.ids did not land in /usr/share/hwdata"; exit 1; }
popd
rm -rf /tmp/hwdata

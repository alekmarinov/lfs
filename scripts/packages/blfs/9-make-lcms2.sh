#!/bin/bash
# PACKAGE:  lcms2
# SOURCE:   lcms2-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-Little CMS 2.."

# lcms2
# Colour management. WebKit uses it for ICC profiles in images, and openjpeg
# links it too.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/lcms2.html
#
# BUILD_REQUIRES: 10-make-libjpeg-turbo 10-make-libtiff
# RUNTIME_REQUIRES:

rm -rf /tmp/lcms2
tar -xf /sources/lcms2-*.tar.gz -C /tmp/
mv /tmp/lcms2-* /tmp/lcms2
pushd /tmp/lcms2
./configure --prefix=/usr --disable-static
make
make install
popd
rm -rf /tmp/lcms2

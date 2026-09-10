#!/bin/bash
# PACKAGE:  libvpx
# SOURCE:   libvpx-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libvpx.."
echo "Approximate build time: 1.5 SBU"
echo "Required disk space: 200 MB"

# libvpx
# VP8 and VP9. VP9 is what YouTube serves for almost everything, so this is the
# one codec that decides whether video plays at all.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/multimedia/libvpx.html
#
# BUILD_REQUIRES: 8.69-make-make 8.51-make-python 12-make-which
# RUNTIME_REQUIRES:
#
# NOTE it builds out of tree by choice: libvpx's configure refuses to run in
# the source directory and says so, rather than producing a broken build.
#
# NOTE --enable-shared --disable-static: the default is the other way round,
# and a static-only libvpx leaves gst-plugins-good with nothing to link.

rm -rf /tmp/libvpx
tar -xf /sources/libvpx-*.tar.gz -C /tmp/
mv /tmp/libvpx-[0-9]* /tmp/libvpx
pushd /tmp/libvpx
sed -i 's/cp -p/cp/' build/make/Makefile
mkdir libvpx-build
cd libvpx-build
../configure --prefix=/usr \
             --enable-shared \
             --disable-static \
             --disable-examples \
             --disable-unit-tests \
             --enable-vp8 \
             --enable-vp9
make
make install
popd
rm -rf /tmp/libvpx

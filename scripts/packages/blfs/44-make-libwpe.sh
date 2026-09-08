#!/bin/bash
# PACKAGE:  libwpe
# SOURCE:   libwpe-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libwpe.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 15 MB"

# libwpe
# The platform abstraction WPE WebKit renders through. It defines what a
# backend must provide - a surface to draw on, input events, a rendering
# target - and provides none of it itself. wpebackend-fdo is the
# implementation; this is the interface both sides compile against.
#
# https://wpewebkit.org/
#
# BUILD_REQUIRES: 24-make-mesa 24-make-libxkbcommon 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE it links against libEGL for the rendering target types. That is a build
# time dependency on mesa's headers rather than a statement about which
# platform is used at runtime, which is the backend's decision.

rm -rf /tmp/libwpe
tar -xf /sources/libwpe-*.tar.xz -C /tmp/
mv /tmp/libwpe-[0-9]* /tmp/libwpe
pushd /tmp/libwpe
mkdir build
cd build
meson setup --prefix=/usr \
            --buildtype=release \
            --wrap-mode=nofallback \
            ..
ninja
ninja install
popd
rm -rf /tmp/libwpe

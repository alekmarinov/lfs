#!/bin/bash
# PACKAGE:  wpebackend-fdo
# SOURCE:   wpebackend-fdo-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-wpebackend-fdo.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 40 MB"

# wpebackend-fdo
# The freedesktop backend for libwpe: it puts WPE's output on a Wayland
# surface and feeds it Wayland input.
#
# This is the package that makes the stack Wayland-only. There is no X11
# backend - WPE's answer to X is to run under a compositor like anything else,
# and an appliance with no compositor uses cog's DRM platform instead of this.
#
# https://wpewebkit.org/
#
# BUILD_REQUIRES: 44-make-libwpe 24-make-wayland 24-make-wayland-protocols 9-make-glib 24-make-mesa 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE it needs mesa built with the wayland platform. With -Dplatforms=x11
# alone libEGL has no wayland-egl support, and this compiles but produces a
# backend that cannot create a surface at runtime - a failure that looks like
# a driver problem rather than a build option.

rm -rf /tmp/wpebackend-fdo
tar -xf /sources/wpebackend-fdo-*.tar.xz -C /tmp/
mv /tmp/wpebackend-fdo-[0-9]* /tmp/wpebackend-fdo
pushd /tmp/wpebackend-fdo
mkdir build
cd build
meson setup --prefix=/usr \
            --buildtype=release \
            --wrap-mode=nofallback \
            ..
ninja
ninja install
popd
rm -rf /tmp/wpebackend-fdo

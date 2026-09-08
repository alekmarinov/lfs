#!/bin/bash
# PACKAGE:  cog
# SOURCE:   cog-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-cog.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 60 MB"

# cog
# The launcher that makes wpewebkit a browser: a single window, a URL, and no
# chrome around it. This is what an appliance actually runs.
#
# It carries the platform plugins, and they are the choice this distro has to
# make. 'wayland' renders into a compositor. 'drm' renders straight to KMS
# with no compositor at all, which is the classic kiosk arrangement and the
# reason WPE is worth having on a device with one screen and no desktop.
# Both are built here so the decision stays with the image rather than the
# package.
#
# https://wpewebkit.org/
#
# BUILD_REQUIRES: 44-make-wpewebkit 44-make-wpebackend-fdo 44-make-libwpe 9-make-libsoup3 9-make-glib 24-make-wayland 24-make-wayland-protocols 24-make-libxkbcommon 24-make-libdrm 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE COG_PLATFORM_NAME at runtime, or --platform, selects between them.

rm -rf /tmp/cog
tar -xf /sources/cog-*.tar.xz -C /tmp/
mv /tmp/cog-[0-9]* /tmp/cog
pushd /tmp/cog
mkdir build
cd build
meson setup --prefix=/usr \
            --buildtype=release \
            --wrap-mode=nofallback \
            -Dplatforms=wayland,drm \
            ..
ninja
ninja install
popd
rm -rf /tmp/cog

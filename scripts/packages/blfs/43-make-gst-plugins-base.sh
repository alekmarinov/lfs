#!/bin/bash
# PACKAGE:  gst-plugins-base
# SOURCE:   gst-plugins-base-*.tar.xz
# RELEASE:  2
# CLASS:    extra
set -e
echo "Building BLFS-gst-plugins-base.."

# gst-plugins-base
# The elements every gstreamer pipeline is built from - decoders, converters,
# sinks. WebKit requires this one by name.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/multimedia/gst10-plugins-base.html
#
# BUILD_REQUIRES: 43-make-gstreamer 9-make-opus 9-make-glib 24-make-xorg-libraries 24-make-mesa 42-make-alsa-lib 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE opus is a build dependency and not an optional extra. opusdec lives
# here, not in -good, and meson builds it only if libopus is present at
# configure time - silently omitting it otherwise. This package was first
# built four days before opus existed in the tree, so it shipped without the
# decoder, and YouTube - which serves Opus audio in every WebM stream - killed
# the web process rather than play anything.
#
# NOTE --wrap-mode=nodownload. meson would otherwise fetch missing optional
# dependencies as subprojects, and the build chroot has no network - the
# failure then reads as a download error rather than a missing package.

rm -rf /tmp/gst-plugins-base
tar -xf /sources/gst-plugins-base-*.tar.xz -C /tmp/
mv /tmp/gst-plugins-base-* /tmp/gst-plugins-base
pushd /tmp/gst-plugins-base
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      --wrap-mode=nodownload
ninja
ninja install
popd
rm -rf /tmp/gst-plugins-base

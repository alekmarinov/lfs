#!/bin/bash
# PACKAGE:  gst-plugins-bad
# SOURCE:   gst-plugins-bad-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-gst-plugins-bad.."

# gst-plugins-bad
# "bad" is about the maturity of the code, not its licence - it is where
# elements live until they are considered stable. WebKit requires it for
# Media Source Extensions, which is what most video on the web now uses.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/multimedia/gst10-plugins-bad.html
#
# BUILD_REQUIRES: 43-make-gst-plugins-base 43-make-gstreamer 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE -D gpl=enabled is the book's, and it is a licensing choice rather than
# a technical one: it allows elements whose dependencies are GPL. Everything
# shipped here is already GPL, so it costs nothing - but a distro that had to
# stay permissive would set this to disabled.
#
# NOTE the many hardware and platform options in this package - magicleap,
# v4l2codecs and the rest - are meson 'feature' options set to auto, so they
# disable themselves when their SDKs are absent rather than failing.

rm -rf /tmp/gst-plugins-bad
tar -xf /sources/gst-plugins-bad-*.tar.xz -C /tmp/
mv /tmp/gst-plugins-bad-* /tmp/gst-plugins-bad
pushd /tmp/gst-plugins-bad
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      --wrap-mode=nodownload \
      -D gpl=enabled
ninja
ninja install
popd
rm -rf /tmp/gst-plugins-bad

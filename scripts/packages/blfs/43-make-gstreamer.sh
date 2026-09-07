#!/bin/bash
# PACKAGE:  gstreamer
# SOURCE:   gstreamer-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-GStreamer.."

# gstreamer
# The media framework core. WebKit plays every <audio> and <video> element
# through it, and will not build without it.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/multimedia/gstreamer10.html
#
# BUILD_REQUIRES: 9-make-glib 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE -D gst_debug=false is a plain boolean here, not a meson 'feature', so
# false is the right spelling. It drops the debug logging infrastructure,
# which is a large part of the library and of no use in an appliance.

rm -rf /tmp/gstreamer
tar -xf /sources/gstreamer-*.tar.xz -C /tmp/
mv /tmp/gstreamer-* /tmp/gstreamer
pushd /tmp/gstreamer
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      -D gst_debug=false
ninja
ninja install
popd
rm -rf /tmp/gstreamer

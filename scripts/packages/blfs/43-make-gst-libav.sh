#!/bin/bash
# PACKAGE:  gst-libav
# SOURCE:   gst-libav-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-gst-libav.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 30 MB"

# gst-libav
# The bridge from gstreamer to libavcodec: one plugin, and with it avdec_h264
# and avdec_aac appear. Without it the registry holds H.264 parsers,
# timestampers and RTP payloaders and not one thing that decodes - which is a
# confusing state to debug, because 'gst-inspect-1.0 | grep h264' looks busy.
#
# Its version must match gstreamer exactly, like the rest of the set.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/multimedia/gst10-libav.html
#
# BUILD_REQUIRES: 43-make-gstreamer 43-make-gst-plugins-base 9-make-ffmpeg 9-make-glib 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE --wrap-mode=nodownload, as for the rest of the gstreamer packages: with
# no network in the chroot, a missing dependency would otherwise be reported
# as a failed subproject download.

rm -rf /tmp/gst-libav
tar -xf /sources/gst-libav-*.tar.xz -C /tmp/
mv /tmp/gst-libav-[0-9]* /tmp/gst-libav
pushd /tmp/gst-libav
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      --wrap-mode=nodownload
ninja
ninja install
popd
rm -rf /tmp/gst-libav

#!/bin/bash
# PACKAGE:  ffmpeg
# SOURCE:   ffmpeg-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-ffmpeg.."
echo "Approximate build time: 4.5 SBU"
echo "Required disk space: 1.5 GB"

# ffmpeg
# Here for exactly one reason: gst-libav wraps libavcodec, and libavcodec is
# the only H.264 and AAC decoder this system can get. Everything else on a
# video page was already covered - VP9 by libvpx, Opus by gst-plugins-base -
# and a browser with those and no H.264 still tells the user it cannot play
# the video, because the site probes for both before it will start.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/multimedia/ffmpeg.html
#
# BUILD_REQUIRES: 13-make-nasm 8.6-make-zlib 8.7-make-bzip2 8.8-make-xz 8.69-make-make
# RUNTIME_REQUIRES:
#
# NOTE the native decoders are what we want, and they are on by default. No
# --enable-gpl, no --enable-nonfree, and no external codec libraries: those
# bring licence terms this repository has no reason to take on, and the
# built-in h264 and aac decoders are LGPL and sufficient.
#
# NOTE --disable-doc. The documentation needs texi2html and doxygen at build
# time and nothing reads it on the target.
#
# NOTE --enable-shared with --disable-static: gst-libav links the shared
# libraries, and a static-only ffmpeg leaves it with nothing to find.

rm -rf /tmp/ffmpeg
tar -xf /sources/ffmpeg-*.tar.xz -C /tmp/
mv /tmp/ffmpeg-[0-9]* /tmp/ffmpeg
pushd /tmp/ffmpeg
./configure --prefix=/usr \
            --enable-shared \
            --disable-static \
            --disable-debug \
            --disable-doc \
            --enable-avfilter \
            --enable-pic
make
make install
popd
rm -rf /tmp/ffmpeg

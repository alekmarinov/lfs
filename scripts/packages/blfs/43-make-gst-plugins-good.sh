#!/bin/bash
# PACKAGE:  gst-plugins-good
# SOURCE:   gst-plugins-good-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-gst-plugins-good.."
echo "Approximate build time: 0.5 SBU"
echo "Required disk space: 200 MB"

# gst-plugins-good
# The containers and codecs a real page needs: qtdemux and matroskademux pull
# apart what YouTube ships, and the vpx and opus wrappers decode what is
# inside. gstreamer and -base give the framework and almost no decoders, which
# is why a browser built on them alone loads a video page and then kills its
# own renderer.
#
# Its version must match gstreamer and gst-plugins-base exactly - the plugins
# are built against the core's internal API, not just its soname.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/multimedia/gst10-plugins-good.html
#
# BUILD_REQUIRES: 43-make-gst-plugins-base 43-make-gstreamer 9-make-libvpx 9-make-opus 9-make-glib 10-make-libpng 10-make-libjpeg-turbo 42-make-alsa-lib 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE --wrap-mode=nodownload, as for the rest of the gstreamer set: the build
# chroot has no network, and without this a missing optional dependency
# reports as a failed download instead of as missing.

rm -rf /tmp/gst-plugins-good
tar -xf /sources/gst-plugins-good-*.tar.xz -C /tmp/
mv /tmp/gst-plugins-good-[0-9]* /tmp/gst-plugins-good
pushd /tmp/gst-plugins-good
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      --wrap-mode=nodownload
ninja
ninja install
popd
rm -rf /tmp/gst-plugins-good

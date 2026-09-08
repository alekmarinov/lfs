#!/bin/bash
# PACKAGE:  wpewebkit
# SOURCE:   wpewebkit-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-wpewebkit.."
echo "Approximate build time: 30 - 100 SBU"
echo "Required disk space: 12 GB"

# wpewebkit
# WebKit with no toolkit and no window system of its own. Everything it draws
# goes through libwpe to a backend; everything it plays goes through
# GStreamer. That is what makes it the engine for an appliance rather than a
# desktop browser: nothing of GTK, X or a UI is compiled in.
#
# It is a library, not a browser. cog is the launcher that turns it into one.
#
# https://wpewebkit.org/
#
# BUILD_REQUIRES: 44-make-libwpe 44-make-wpebackend-fdo 9-make-icu 9-make-libsoup3 9-make-libxslt 9-make-libwebp 9-make-openjpeg2 9-make-lcms2 9-make-libsecret 9-make-libtasn1 9-make-libgcrypt 43-make-gstreamer 43-make-gst-plugins-base 43-make-gst-plugins-bad 10-make-harfbuzz 10-make-freetype 10-make-fontconfig 10-make-libjpeg-turbo 10-make-libpng 25-make-cairo 22-make-sqlite 24-make-mesa 24-make-libxkbcommon 13-make-cmake 13-make-ruby 13-make-unifdef 8.39-make-gperf 8.51-make-python 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE ruby and unifdef are build tools only, which is why both are
# '# CLASS: bootstrap' and never published. WebKit's code generators are Ruby,
# and unifdef trims the generated headers.
#
# NOTE the ports that are turned off matter more than the ones left on. This
# is the WPE port: no GTK, no X11, no introspection, no API documentation and
# no test harness. Every one of those pulls a dependency this system has no
# reason to carry, and the build is long enough without them.
#
# NOTE -DCMAKE_BUILD_TYPE=Release rather than the book's default. A debug or
# RelWithDebInfo build of WebKit produces several gigabytes of symbols that
# strip-packages.sh then has to walk.
#
# NOTE this is the longest build in the tree, Firefox included. Expect hours.

rm -rf /tmp/wpewebkit
tar -xf /sources/wpewebkit-*.tar.xz -C /tmp/
mv /tmp/wpewebkit-[0-9]* /tmp/wpewebkit
pushd /tmp/wpewebkit
mkdir build
cd build
cmake -DPORT=WPE \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_SKIP_INSTALL_RPATH=ON \
      -DENABLE_DOCUMENTATION=OFF \
      -DENABLE_INTROSPECTION=OFF \
      -DENABLE_JOURNALD_LOG=OFF \
      -DENABLE_WEB_RTC=ON \
      -DUSE_SOUP2=OFF \
      -DUSE_SYSTEMD=OFF \
      -DENABLE_MINIBROWSER=OFF \
      -Wno-dev \
      ..
ninja
ninja install
popd
rm -rf /tmp/wpewebkit

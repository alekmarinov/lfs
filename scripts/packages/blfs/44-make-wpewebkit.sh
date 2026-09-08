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
# NOTE speech synthesis is off. WebKit's implementation wants Flite, a small
# text to speech engine, and enabling it would mean carrying a second speech
# stack: the appliance already synthesises speech through audi, which is the
# component whose whole job that is. The cost is that a page calling the Web
# Speech API's speechSynthesis gets nothing - worth knowing if a page is ever
# expected to talk on its own rather than through the adapters.
#
# NOTE five options WebKit turns on by default are turned off here, and the
# reasoning differs for each rather than being "we did not have the library":
#
#   USE_JPEGXL      JPEG XL is barely deployed - Chrome removed support - and
#                   libjxl would pull brotli and highway to decode it.
#   USE_AVIF        growing, but a page serving AVIF almost always serves a
#                   JPEG beside it. Decoding it needs dav1d, an AV1 decoder,
#                   which is a real dependency to carry for a fallback.
#   USE_LIBHYPHEN   automatic hyphenation. Cosmetic.
#   USE_LIBBACKTRACE  symbolised crash traces. A developer aid on a machine
#                   nobody debugs on.
#
# WOFF2 is deliberately NOT in that list. It is how essentially every site
# ships its fonts, and a browser without it renders real pages in fallback
# fonts - visibly wrong rather than subtly degraded. brotli and woff2 are
# built for it.
#
# NOTE -G Ninja because the build below runs ninja. Without it cmake writes
# Makefiles, configure reports success, and ninja then fails on a build.ninja
# that was never generated.
#
# NOTE USE_SOUP2 and USE_SYSTEMD are not passed: 2.52.6 knows neither, and
# cmake reports unused variables rather than failing on them, so they would
# sit here looking meaningful forever. libsoup 3 is the only option now.
#
# NOTE USE_SYSTEM_SYSPROF_CAPTURE=NO uses the copy of libsysprof-capture that
# WebKit already carries, rather than requiring one on the system. sysprof is
# a profiler's data capture library; nothing here profiles WebKit, and the
# bundled copy is what upstream builds against anyway. This is the wording the
# configure error itself suggests.
#
# NOTE the bubblewrap sandbox is off, which is a security decision and not a
# packaging one. With it on, the process that parses HTML, images and fonts
# from the network runs confined; with it off, a bug in that parser is a bug
# in the appliance. It is off because this browser is expected to display
# content the deployment controls. If it is ever pointed at the open web,
# build bubblewrap and xdg-dbus-proxy and turn this back on.
#
# NOTE this is the longest build in the tree, Firefox included. Expect hours.

rm -rf /tmp/wpewebkit
tar -xf /sources/wpewebkit-*.tar.xz -C /tmp/
mv /tmp/wpewebkit-[0-9]* /tmp/wpewebkit
pushd /tmp/wpewebkit
mkdir build
cd build
cmake -G Ninja \
      -DPORT=WPE \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_SKIP_INSTALL_RPATH=ON \
      -DENABLE_DOCUMENTATION=OFF \
      -DENABLE_INTROSPECTION=OFF \
      -DENABLE_JOURNALD_LOG=OFF \
      -DENABLE_WEB_RTC=ON \
      -DENABLE_MINIBROWSER=OFF \
      -DENABLE_SPEECH_SYNTHESIS=OFF \
      -DENABLE_BUBBLEWRAP_SANDBOX=OFF \
      -DUSE_JPEGXL=OFF \
      -DUSE_AVIF=OFF \
      -DUSE_LIBHYPHEN=OFF \
      -DUSE_LIBBACKTRACE=OFF \
      -DUSE_SYSTEM_SYSPROF_CAPTURE=NO \
      -Wno-dev \
      ..
ninja
ninja install
popd
rm -rf /tmp/wpewebkit

#!/bin/bash
# PACKAGE:  libxkbcommon
# SOURCE:   libxkbcommon-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libxkbcommon.."

# libxkbcommon
# Keymap handling without an X server. This is what lets a Wayland compositor
# - or WPE talking straight to KMS - interpret a keyboard at all, where an X
# client would have asked the server.
#
# It reads its data from xkeyboard-config at runtime, which is why that is a
# runtime dependency rather than a build one.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/libxkbcommon.html
#
# BUILD_REQUIRES: 24-make-wayland 24-make-wayland-protocols 24-make-xorg-libraries 8.57-make-meson 8.56-make-ninja 8.15-make-flex 7.8-make-bison
# RUNTIME_REQUIRES: 24-make-xkeyboard-config
#
# NOTE -D enable-docs=false: the documentation needs doxygen, which is a build
# dependency worth avoiding for a library nobody reads the API of here.

rm -rf /tmp/libxkbcommon
tar -xf /sources/libxkbcommon-*.tar.gz -C /tmp/
mv /tmp/libxkbcommon-* /tmp/libxkbcommon
pushd /tmp/libxkbcommon
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      -D enable-docs=false
ninja
ninja install
popd
rm -rf /tmp/libxkbcommon

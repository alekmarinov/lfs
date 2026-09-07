#!/bin/bash
# PACKAGE:  wayland
# SOURCE:   wayland-[0-9]*.tar.xz
# VERSION:  1.24.0
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-Wayland.."

# wayland
# The display server protocol and its client/server libraries.
#
# Present so that a distro can be assembled either way: the X stack here is
# unchanged and still complete, and nothing installs wayland unless a distro's
# packages.list asks for it. WPE can run over a Wayland compositor through
# WPEBackend-fdo, or straight on KMS with no display server at all - this is
# the package the first of those needs.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/wayland.html
#
# BUILD_REQUIRES: 9-make-libxml2 8.50-make-libffi 8.40-make-expat 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the SOURCE glob is pinned to [0-9] so it cannot also match
# wayland-protocols-*.tar.xz, which sits beside it in /sources.
#
# NOTE -D documentation=false: the docs need doxygen, xmlto and graphviz.

rm -rf /tmp/wayland
tar -xf /sources/wayland-[0-9]*.tar.xz -C /tmp/
mv /tmp/wayland-[0-9]* /tmp/wayland
pushd /tmp/wayland
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      -D documentation=false
ninja
ninja install
popd
rm -rf /tmp/wayland

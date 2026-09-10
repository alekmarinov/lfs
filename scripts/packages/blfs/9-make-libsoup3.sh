#!/bin/bash
# PACKAGE:  libsoup3
# SOURCE:   libsoup-3*.tar.xz
# VERSION:  3.6.5
# RELEASE:  2
# CLASS:    extra
set -e
echo "Building BLFS-libsoup 3.."

# libsoup3
# The HTTP client library WebKit uses for every network request.
#
# NOTE the package is libsoup3 and the tarball is libsoup-3.x - the 3 in the
# name is deliberate, because libsoup 2 and 3 install side by side with
# different sonames and a tree may end up with both.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/libsoup3.html
#
# BUILD_REQUIRES: 9-make-glib-networking 9-make-libpsl 9-make-libxml2 9-make-nghttp2 22-make-sqlite 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES: 9-make-glib-networking
#
# glib-networking is a runtime dependency no ELF header can show. It installs
# a GIO module, /usr/lib/gio/modules/libgiognutls.so, which glib opens by
# dlopen when a soup session first needs TLS - so the dependency graph, which
# is derived from DT_NEEDED, cannot see it and a distro list built from that
# graph leaves it out. The system then resolves, boots, and fails on the first
# https:// request with no explanation.
#
# NOTE the sed on docs/reference/meson.build is the book's: the docs target
# refers to a variable the current gi-docgen no longer defines, and meson
# parses that file whether or not the docs are built.
#
# NOTE --wrap-mode=nofallback stops meson downloading a subproject when an
# optional dependency is missing. There is no network in the build chroot, so
# the failure would otherwise be a confusing download error rather than a
# clear "not found".

rm -rf /tmp/libsoup3
tar -xf /sources/libsoup-3*.tar.xz -C /tmp/
mv /tmp/libsoup-3* /tmp/libsoup3
pushd /tmp/libsoup3
sed 's/apiversion/soup_version/' -i docs/reference/meson.build
mkdir build
cd build
meson setup --prefix=/usr \
            --buildtype=release \
            --wrap-mode=nofallback \
            ..
ninja
ninja install
popd
rm -rf /tmp/libsoup3

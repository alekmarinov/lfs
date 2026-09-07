#!/bin/bash
# PACKAGE:  libsecret
# SOURCE:   libsecret-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libsecret.."

# libsecret
# Client library for a Secret Service - where WebKit would keep saved
# passwords. The service itself is not here, so this satisfies the link and
# does nothing until one exists.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/libsecret.html
#
# BUILD_REQUIRES: 9-make-glib 9-make-libgcrypt 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE four options are turned off which the book leaves alone, because unlike
# most such switches these are plain booleans defaulting to true - they do not
# quietly skip themselves when their tooling is absent, they fail the
# configure:
#   introspection  needs gobject-introspection, which this tree does not have
#   vapi           needs vala
#   gtk_doc        needs gi-docgen
#   manpage        needs xsltproc and the docbook stylesheets

rm -rf /tmp/libsecret
tar -xf /sources/libsecret-*.tar.xz -C /tmp/
mv /tmp/libsecret-* /tmp/libsecret
pushd /tmp/libsecret
mkdir bld
cd bld
meson setup --prefix=/usr \
            --buildtype=release \
            -D introspection=false \
            -D vapi=false \
            -D gtk_doc=false \
            -D manpage=false \
            ..
ninja
ninja install
popd
rm -rf /tmp/libsecret

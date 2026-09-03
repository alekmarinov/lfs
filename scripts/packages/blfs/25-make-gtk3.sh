#!/bin/bash
# PACKAGE:  gtk3
# SOURCE:   gtk+-3*.tar.xz
# VERSION:  3.24.34
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-gtk3.."

# gtk3
# The toolkit. This is the point of the whole chain below it: Firefox has no
# other option on linux, and gtk is what forces Mesa into the build through
# libepoxy.
#
# wayland and broadway backends are off - this distro has an X server and no
# compositor - and introspection is off so gobject-introspection is not needed.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/gtk3.html
#
# BUILD_REQUIRES: 25-make-gdk-pixbuf 25-make-pango 25-make-at-spi2-atk 25-make-libepoxy 25-make-cairo 9-make-glib 24-make-xorg-libraries 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the C args. GTK 3 passes subclass pointers where the declared parameter
# is a different widget type, relying on the cast being harmless, and GCC 14
# turned that from a warning into an error. It also declares functions such as
# _gtk_get_slowdown with an empty parameter list while defining them with
# arguments, which only agree before C23.
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/gtk3
tar -xf /sources/gtk+-3*.tar.xz -C /tmp/
mv /tmp/gtk+-3* /tmp/gtk3
pushd /tmp/gtk3
mkdir build
pushd build
meson --prefix=/usr \
      --buildtype=release \
      -Dman=false \
      -Dgtk_doc=false \
      -Dintrospection=false \
      -Dx11_backend=true \
      -Dwayland_backend=false \
      -Dbroadway_backend=false \
      -Dprint_backends=file \
      -Dc_args="-std=gnu17 -Wno-error=incompatible-pointer-types" \
      ..
ninja
ninja install
popd
popd
rm -rf /tmp/gtk3

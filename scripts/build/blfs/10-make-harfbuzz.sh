#!/bin/bash
set -e
echo "Building BLFS-harfbuzz.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 135 MB"

# 10. harfbuzz
# The HarfBuzz package contains an OpenType text shaping engine.
# recommended: gobject-introspection(for gnome),glib,(for pango),
#              graphite2(for texlive/libre),icu,freetype2
# optional: cairo,git,gtk-doc
# https://www.linuxfromscratch.org/blfs/view/svn/general/harfbuzz.html

VER=$(ls /sources/harfbuzz-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/harfbuzz-* -C /tmp/ \
    && mv /tmp/harfbuzz-* /tmp/harfbuzz \
    && pushd /tmp/harfbuzz \
    && mkdir build \
    && cd build \
    && meson \
        --prefix=/usr \
        --buildtype=release \
        -Dgraphite2=enabled \
    && ninja \
    && if [ $LFS_TEST -eq 1 ]; then ninja test || true; fi \
    && ninja install \
    && popd \
    && rm -rf /tmp/harfbuzz

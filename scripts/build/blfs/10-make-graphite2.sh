#!/bin/bash
set -e
echo "Building BLFS-graphite2.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 28 MB"

# 10. graphite2
# Graphite2 is a rendering engine for graphite fonts. 
# These are TrueType fonts with additional tables containing smart rendering 
# information and were originally developed to support complex non-Roman writing systems.
# They may contain rules for e.g. ligatures, glyph substitution, kerning, justification -
# this can make them useful even on text written in Roman writing systems such as English.
# required: cmake
# optional: freetype2,silgraphite,harfbuzz,asciidoc(for docs),doxygen,texlive/install-tl-useful,
# https://www.linuxfromscratch.org/blfs/view/svn/general/graphite2.html

VER=$(ls /sources/graphite2-*.tgz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/graphite2-*.tgz -C /tmp/ \
    && mv /tmp/graphite2-* /tmp/graphite2 \
    && pushd /tmp/graphite2 \
    && sed -i '/cmptest/d' tests/CMakeLists.txt \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr .. \
    && make \
    && if [ $LFS_DOCS -eq 1 ]; then make docs; fi \
    && if [ $LFS_TEST -eq 1 ]; then make test || true; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -d -m755 /usr/share/doc/graphite2-$VER \
        && cp -v -f doc/{GTF,manual}.html \
            /usr/share/doc/graphite2-$VER \
        && cp -v -f doc/{GTF,manual}.pdf \
            /usr/share/doc/graphite2-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/graphite2

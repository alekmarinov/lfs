#!/bin/bash
set -e
echo "Building BLFS-freetype2.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 31 MB"

# 10. freetype2
# The FreeType2 package contains a library which allows applications to 
# properly render TrueType fonts.
# recommended: harfbuzz,libpng,which
# optional: brotli,docwriter(for doc)
# https://www.linuxfromscratch.org/blfs/view/svn/general/freetype2.html

VER=$(ls /sources/freetype-*.tar.xz | head -1 | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/freetype-$VER.tar.xz -C /tmp/ \
    && mv /tmp/freetype-* /tmp/freetype2 \
    && pushd /tmp/freetype2 \
    && if [ $LFS_DOCS -eq 1 ]; then \
        tar -xf /sources/freetype-doc-$VER.tar.xz --strip-components=2 -C docs; \
    fi \
    && sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg \
    && sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
        -i include/freetype/config/ftoption.h \
    && ./configure --prefix=/usr --enable-freetype-config --disable-static \
    && make \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -m755 -d /usr/share/doc/freetype-$VER \
            && cp -v -R docs/*     /usr/share/doc/freetype-$VER \
            && rm -v /usr/share/doc/freetype-$VER/freetype-config.1;
    fi \
    && popd \
    && rm -rf /tmp/freetype2

#!/bin/bash
set -e
echo "Building BLFS-libpng.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 15 MB"

# 10. libpng
# The libpng package contains libraries used by other programs for reading and writing PNG files.
# The PNG format was designed as a replacement for GIF and, to a lesser extent, TIFF, 
# with many improvements and extensions and lack of patent problems.
# https://www.linuxfromscratch.org/blfs/view/svn/general/libpng.html

VER=$(ls /sources/libpng-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/libpng-* -C /tmp/ \
    && mv /tmp/libpng-* /tmp/libpng \
    && pushd /tmp/libpng \
    && gzip -cd /sources/libpng-$VER-apng.patch.gz | patch -p1 \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && mkdir -v /usr/share/doc/libpng-$VER \
    && cp -v README libpng-manual.txt /usr/share/doc/libpng-$VER \
    && popd \
    && rm -rf /tmp/libpng

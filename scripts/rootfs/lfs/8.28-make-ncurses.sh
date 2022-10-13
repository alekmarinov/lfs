#!/bin/bash
set -e
echo "Building ncurses.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 45 MB"

# 8.28. Ncurses
# The Ncurses package contains libraries for terminal-independent handling of character screens.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/ncurses.html

VER=$(ls /sources/ncurses-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/ncurses-*.tar.gz -C /tmp/ \
    && mv /tmp/ncurses-* /tmp/ncurses \
    && pushd /tmp/ncurses \
    && ./configure \
        --prefix=/usr \
        --mandir=/usr/share/man \
        --with-shared \
        --without-debug \
        --without-normal \
        --with-cxx-shared \
        --enable-pc-files \
        --enable-widec \
        --with-pkg-config-libdir=/usr/lib/pkgconfig \
    && make \
    && make DESTDIR=$PWD/dest install \
    && install -vm755 dest/usr/lib/libncursesw.so.$VER /usr/lib \
    && rm -v  dest/usr/lib/libncursesw.so.$VER \
    && cp -av dest/* / \
    && for lib in ncurses form panel menu ; do \
        rm -vf                    /usr/lib/lib${lib}.so; \
        echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so; \
        ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc; \
    done \
    && rm -vf                     /usr/lib/libcursesw.so \
    && echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so \
    && ln -sfv libncurses.so      /usr/lib/libcurses.so \
    && if [ $LFS_DOCS -eq 1 ]; then \
        mkdir -pv      /usr/share/doc/ncurses-$VER; \
        cp -v -R doc/* /usr/share/doc/ncurses-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/ncurses

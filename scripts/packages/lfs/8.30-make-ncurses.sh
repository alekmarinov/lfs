#!/bin/bash
set -e
echo "Building ncurses.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 45 MB"

# 8.28. Ncurses
# The Ncurses package contains libraries for terminal-independent handling of character screens.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/ncurses.html
#
# NOTE the old terminfo tree is removed before the copy. The tools ncurses
# left its aliases as symlinks while this install ships them as hard-linked
# regular files, and 'cp -a' writing a file through a stale symlink chains
# them together until the path exceeds the symlink limit. The new tree is
# complete on its own, so nothing is lost by clearing the old one first.
#
# NOTE the shared library is found rather than named. Its soname version and
# the release version are not the same thing: 12.4 ships the dated snapshot
# 6.5-20250809, whose library is still libncursesw.so.6.5. -type f picks the
# real file and not the .so / .so.6 symlinks beside it.

VER=$(ls /sources/ncurses-*.t* | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/ncurses-*.t* -C /tmp/ \
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
    && SOFILE=$(find dest/usr/lib -maxdepth 1 -type f -name 'libncursesw.so.*') \
    && install -vm755 $SOFILE /usr/lib \
    && rm -v  $SOFILE \
    && rm -rf /usr/share/terminfo \
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

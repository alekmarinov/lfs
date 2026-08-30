#!/bin/bash
set -e
echo "Building readline.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 15 MB"

# 8.11. Readline
# The Readline package is a set of libraries that offers command-line editing and history capabilities.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/readline.html

VER=$(ls /sources/readline-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/readline-*.tar.gz -C /tmp/ \
    && mv /tmp/readline-* /tmp/readline \
    && pushd /tmp/readline \
    && sed -i '/MV.*old/d' Makefile.in \
    && sed -i '/{OLDSUFF}/c:' support/shlib-install \
    && ./configure --prefix=/usr    \
        --disable-static \
        --with-curses    \
        --docdir=/usr/share/doc/readline-$VER \
    && make SHLIB_LIBS="-lncursesw" \
    && make SHLIB_LIBS="-lncursesw" install \
    && install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-$VER \
    && popd \
    && rm -rf /tmp/readline

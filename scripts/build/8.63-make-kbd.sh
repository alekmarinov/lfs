#!/bin/bash
set -e
echo "Building kbd.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 35 MB"

# 8.63. Kbd
# The Kbd package contains key-table files, console fonts, and keyboard utilities.
VER=$(ls /sources/kbd-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/kbd-*.tar.xz -C /tmp/ \
    && mv /tmp/kbd-* /tmp/kbd \
    && pushd /tmp/kbd \
    && patch -Np1 -i $(ls /sources/kbd-*-backspace-1.patch) \
    && sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure \
    && sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in \
    && ./configure \
        --prefix=/usr \
        --disable-vlock \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        mkdir -v /usr/share/doc/kbd-$VER \
        cp -R -v docs/doc/* /usr/share/doc/kbd-$VER \
    fi
    && popd \
    && rm -rf /tmp/kbd

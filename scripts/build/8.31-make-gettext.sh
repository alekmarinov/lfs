#!/bin/bash
set -e
echo "Building gettext.."
echo "Approximate build time: 2.7 SBU"
echo "Required disk space: 235 MB"

# 8.31. Gettext
# The Gettext package contains utilities for internationalization and localization.
# These allow programs to be compiled with NLS (Native Language Support),
# enabling them to output messages in the user's native language.
VER=$(ls /sources/gettext-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/gettext-*.tar.xz -C /tmp/ \
    && mv /tmp/gettext-* /tmp/gettext \
    && pushd /tmp/gettext \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/gettext-$VER \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && chmod -v 0755 /usr/lib/preloadable_libintl.so \
    && popd \
    && rm -rf /tmp/gettext

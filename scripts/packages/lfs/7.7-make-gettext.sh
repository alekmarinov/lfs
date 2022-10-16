#!/bin/bash
set -e
echo "Building gettext.."
echo "Approximate build time: 1.6 SBU"
echo "Required disk space: 202 MB"

# 7.7. Gettext
# The Gettext package contains utilities for internationalization and
# localization. These allow programs to be compiled with NLS (Native Language Support),
# enabling them to output messages in the user's native language.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/gettext.html

tar -xf /sources/gettext-*.tar.xz -C /tmp/ \
    && mv /tmp/gettext-* /tmp/gettext \
    && pushd /tmp/gettext \
    && ./configure --disable-shared \
    && make \
    && cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin \
    && popd \
    && rm -rf /tmp/gettext

#!/bin/bash
set -e
echo "Building Intltool.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 1.5 MB"

# 8.43. Intltool
# The Intltool is an internationalization tool used for extracting translatable
# strings from source files.
VER=$(ls /sources/intltool-*.tar.gz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/intltool-*.tar.gz -C /tmp/ \
    && mv /tmp/intltool-* /tmp/intltool \
    && pushd /tmp/intltool
    && sed -i 's:\\\${:\\\$\\{:' intltool-update.in \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-$VER/I18N-HOWTO \
    fi \
    && popd \
    && rm -rf /tmp/intltool

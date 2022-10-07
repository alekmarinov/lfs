#!/bin/bash
set -e
echo "Building Sed.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 31 MB"

# 8.29. Sed
# The Sed package contains a stream editor.
VER=$(ls /sources/sed-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/sed-*.tar.xz -C /tmp/ \
    && mv /tmp/sed-* /tmp/sed \
    && pushd /tmp/sed \
    && ./configure \
        --prefix=/usr \
    && make \
    && make html \
    && if [ $LFS_TEST -eq 1 ]; then \
        chown -Rv tester . \
        su tester -c "PATH=$PATH make check" \
    fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -d -m755           /usr/share/doc/sed-$VER \
        install -m644 doc/sed.html /usr/share/doc/sed-$VER \
    fi \
    && popd \
    && rm -rf /tmp/sed

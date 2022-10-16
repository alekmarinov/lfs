#!/bin/bash
set -e
echo "Building BLFS-nettle.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 90 MB"

# 4. nettle
# The Nettle package contains a low-level cryptographic library that
# is designed to fit easily in many contexts.
# optional: valgrind (for tests)
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/nettle.html

VER=$(ls /sources/nettle-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/nettle-*.tar.gz -C /tmp/ \
    && mv /tmp/nettle-* /tmp/nettle \
    && pushd /tmp/nettle \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make \
    && make install \
    && chmod -v 755 /usr/lib/lib{hogweed,nettle}.so \
    && install -v -m755 -d /usr/share/doc/nettle-$VER \
    && install -v -m644 nettle.html /usr/share/doc/nettle-$VER \
    && popd \
    && rm -rf /tmp/nettle

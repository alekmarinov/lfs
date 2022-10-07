#!/bin/bash
set -e
echo "Building Libelf.."
echo "Approximate build time: 0.9 SBU"
echo "Required disk space: 117 MB"

# 8.48. Libelf from Elfutils
# Libelf is a library for handling ELF (Executable and Linkable Format) files.
tar -xf /sources/elfutils-*.tar.bz2 -C /tmp/ \
    && mv /tmp/elfutils-* /tmp/elfutils \
    && pushd /tmp/elfutils \
    && ./configure \
        --prefix=/usr \
        --disable-debuginfod \
        --enable-libdebuginfod=dummy \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make -C libelf install \
    && install -vm644 config/libelf.pc /usr/lib/pkgconfig \
    && rm /usr/lib/libelf.a
    && popd \
    && rm -rf /tmp/elfutils

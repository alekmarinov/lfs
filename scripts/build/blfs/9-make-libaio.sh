#!/bin/bash
set -e
echo "Building BLFS-libaio.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 1 MB"

# 9. libaio
# Provides the Linux-native API for async I/O
# https://www.linuxfromscratch.org/blfs/view/stable/general/libaio.html

tar -xf /sources/libaio-*.tar.gz -C /tmp/ \
    && mv /tmp/libaio-* /tmp/libaio \
    && pushd /tmp/libaio \
    && sed -i '/install.*libaio.a/s/^/#/' src/Makefile \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then \
        sed 's/-Werror//' -i harness/Makefile; \
        make partcheck; \
    fi \
    && make install \
    && popd \
    && rm -rf /tmp/libaio

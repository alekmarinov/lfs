#!/bin/bash
set -e
echo "Building Grep.."
echo "Approximate build time: 0.8 SBU"
echo "Required disk space: 37 MB"

# 8.33. Grep
# The Grep package contains programs for searching through the contents of files.
tar -xf /sources/grep-*.tar.xz -C /tmp/ \
    && mv /tmp/grep-* /tmp/grep \
    && pushd /tmp/grep \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && popd \
    && rm -rf /tmp/grep

#!/bin/bash
set -e
echo "Building groff.."
echo "Approximate build time: 0.5 SBU"
echo "Required disk space: 88 MB"

# 8.59. Groff
# The Groff package contains programs for processing and formatting text.
tar -xf /sources/groff-*.tar.gz -C /tmp/ \
    && mv /tmp/groff-* /tmp/groff \
    && pushd /tmp/groff \
    && PAGE=A4 ./configure --prefix=/usr \
    && make -j1 \
    && make install \
    && popd \
    && rm -rf /tmp/groff

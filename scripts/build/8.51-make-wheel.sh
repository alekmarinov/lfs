#!/bin/bash
set -e
echo "Building wheel.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 956 KB"

# 8.51. Wheel
# Wheel is a Python library that is the reference implementation of the
# Python wheel packaging standard.
VER=$(ls /sources/wheel-*.tar.gz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/wheel-*.tar.xz -C /tmp/ \
    && mv /tmp/wheel-* /tmp/wheel \
    && pushd /tmp/wheel \
    && pip3 install --no-index $PWD \
    && popd \
    && rm -rf /tmp/python

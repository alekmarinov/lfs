#!/bin/bash
set -e
echo "Building wheel.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 956 KB"

# 8.51. Wheel
# Wheel is a Python library that is the reference implementation of the
# Python wheel packaging standard.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/wheel.html

VER=$(ls /sources/wheel-*.tar.gz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/wheel-*.tar.gz -C /tmp/ \
    && mv /tmp/wheel-* /tmp/wheel \
    && pushd /tmp/wheel \
    && pip3 install --no-index $PWD \
    && popd \
    && rm -rf /tmp/wheel

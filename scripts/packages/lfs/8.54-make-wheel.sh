#!/bin/bash
# PACKAGE:  wheel
# SOURCE:   wheel-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building wheel.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 956 KB"

# 8.51. Wheel
# Wheel is a Python library that is the reference implementation of the
# Python wheel packaging standard.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/wheel.html
#
# NOTE --no-build-isolation. Without it pip builds in a fresh virtualenv that
# cannot see the flit_core installed just before this, and --no-index leaves
# it nowhere to fetch one from, so the build fails on its own dependency.

VER=$(ls /sources/wheel-*.tar.gz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/wheel-*.tar.gz -C /tmp/ \
    && mv /tmp/wheel-* /tmp/wheel \
    && pushd /tmp/wheel \
    && pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD \
    && pip3 install --no-index --find-links dist wheel \
    && popd \
    && rm -rf /tmp/wheel

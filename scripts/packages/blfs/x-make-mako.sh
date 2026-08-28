#!/bin/bash
set -e
echo "Building BLFS-Mako.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 4 MB"

# 9. Mako
# A python templating engine. Mesa generates a large part of its source with it
# at build time, and will not configure without it.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/mako.html
#
# BUILD_REQUIRES: 7.10-make-python x-make-markupsafe
# RUNTIME_REQUIRES:
# BUILD_ONLY: generates part of mesa's source at build time
#
# Build only. This is not listed in any distro's packages.list: python is not
# installed in the images, and nothing needs this once Mesa is compiled.
#
# NOTE --no-build-isolation. Mako's pyproject.toml asks for setuptools>=47 as a
# build requirement, and without it pip builds the package in a fresh
# environment and tries to fetch setuptools from the network, which --no-index
# forbids. The setuptools already installed here is the one to build against.

tar -xf /sources/Mako-*.tar.gz -C /tmp/ \
    && mv /tmp/Mako-* /tmp/mako \
    && pushd /tmp/mako \
    && pip3 install --no-index --no-build-isolation $PWD \
    && popd \
    && rm -rf /tmp/mako

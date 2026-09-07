#!/bin/bash
# PACKAGE:  mako
# SOURCE:   mako-*.tar.gz
# RELEASE:  1
# CLASS:    bootstrap
set -e
echo "Building BLFS-Mako.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 4 MB"

# 9. Mako
# A python templating engine. Mesa generates a large part of its source with it
# at build time, and will not configure without it.
# https://www.linuxfromscratch.org/blfs/view/12.4/general/mako.html
#
# NOTE the [Mm] in the unpack. PyPI renamed the sdist from Mako-x to mako-x, so
# the directory it extracts to depends on the version; matching both keeps this
# working across the rename.
#
# NOTE --upgrade, for the same reason as six: this base already carries the
# previous Mako, and without it pip installs nothing and the package is empty.
#
# BUILD_REQUIRES: 7.10-make-python 8.74-make-markupsafe
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

tar -xf /sources/mako-*.tar.gz -C /tmp/ \
    && mv /tmp/[Mm]ako-* /tmp/mako \
    && pushd /tmp/mako \
    && pip3 install --no-index --no-build-isolation --no-user --upgrade $PWD \
    && popd \
    && rm -rf /tmp/mako

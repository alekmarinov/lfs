#!/bin/bash
set -e
echo "Building BLFS-MarkupSafe.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 2 MB"

# 9. MarkupSafe
# A python module Mako needs, which Mesa's build in turn needs. It is not used
# by anything at run time in this distro.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/markupsafe.html
#
# BUILD_REQUIRES: 7.10-make-python
# RUNTIME_REQUIRES:
# BUILD_ONLY: only mako uses it
#
# Build only. This is not listed in any distro's packages.list: python is not
# installed in the images, and nothing needs this once Mesa is compiled.

tar -xf /sources/MarkupSafe-*.tar.gz -C /tmp/ \
    && mv /tmp/MarkupSafe-* /tmp/markupsafe \
    && pushd /tmp/markupsafe \
    && pip3 install --no-index $PWD \
    && popd \
    && rm -rf /tmp/markupsafe

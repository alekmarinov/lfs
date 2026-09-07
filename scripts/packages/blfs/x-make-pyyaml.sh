#!/bin/bash
# PACKAGE:  pyyaml
# SOURCE:   pyyaml-*.tar.gz
# RELEASE:  1
# CLASS:    bootstrap
set -e
echo "Building PyYAML (build-time only).."

# PyYAML
# The python yaml parser. Mesa 25 generates part of its source with it and
# refuses to configure without it:
#   ERROR: Problem encountered: Python (3.x) yaml module (PyYAML) required to
#   build mesa.
# Mesa 22 did not need it. The book lists it among mesa's required
# dependencies.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/python-modules.html#pyyaml
#
# BUILD_REQUIRES: 7.10-make-python 8.54-make-wheel 8.55-make-setuptools
# RUNTIME_REQUIRES:
# BUILD_ONLY: mesa generates source with it at build time
#
# Build only, like Mako: python is not installed in the images, and nothing
# needs this once mesa is compiled. It is in no distro's packages.list.
#
# NOTE --upgrade for the same reason as six and Mako - this build base is
# cumulative, and without it pip reports the requirement already satisfied,
# installs nothing, and the package comes out empty.
#
# NOTE this builds the pure-python parser. libyaml would make it faster and is
# a separate BLFS package; nothing here is parsing enough yaml to care.

rm -rf /tmp/pyyaml
tar -xf /sources/pyyaml-*.tar.gz -C /tmp/
mv /tmp/[Pp][Yy][Yy][Aa][Mm][Ll]-* /tmp/pyyaml
pushd /tmp/pyyaml
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-cache-dir --no-user --upgrade PyYAML
popd
rm -rf /tmp/pyyaml

#!/bin/bash
# PACKAGE:  packaging
# SOURCE:   packaging-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building packaging.."

# 8.53. packaging
# Version handling used by setuptools and by meson.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/packaging.html
#
# BUILD_REQUIRES: 8.51-make-python
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/packaging
tar -xf /sources/packaging-*.tar.gz -C /tmp/
mv /tmp/packaging-* /tmp/packaging
pushd /tmp/packaging
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist packaging
popd
rm -rf /tmp/packaging

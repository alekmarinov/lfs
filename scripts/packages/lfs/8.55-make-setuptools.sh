#!/bin/bash
# PACKAGE:  setuptools
# SOURCE:   setuptools-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building setuptools.."

# 8.55. setuptools
# The build backend most python packages still use.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/setuptools.html
#
# BUILD_REQUIRES: 8.51-make-python
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/setuptools
tar -xf /sources/setuptools-*.tar.gz -C /tmp/
mv /tmp/setuptools-* /tmp/setuptools
pushd /tmp/setuptools
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools
popd
rm -rf /tmp/setuptools

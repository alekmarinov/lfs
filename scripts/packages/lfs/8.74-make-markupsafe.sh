#!/bin/bash
# PACKAGE:  markupsafe
# SOURCE:   markupsafe-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building markupsafe.."

# 8.74. markupsafe
# String escaping for jinja2. In 12.4 it is a book package; we used to build
# it ourselves because Mesa needs it.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/markupsafe.html
#
# BUILD_REQUIRES: 8.51-make-python
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/markupsafe
tar -xf /sources/markupsafe-*.tar.gz -C /tmp/
mv /tmp/markupsafe-* /tmp/markupsafe
pushd /tmp/markupsafe
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist markupsafe
popd
rm -rf /tmp/markupsafe

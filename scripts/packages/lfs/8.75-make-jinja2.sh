#!/bin/bash
# PACKAGE:  jinja2
# SOURCE:   jinja2-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building jinja2.."

# 8.75. jinja2
# A templating engine. Mesa generates part of its source with it.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/jinja2.html
#
# BUILD_REQUIRES: 8.51-make-python
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/jinja2
tar -xf /sources/jinja2-*.tar.gz -C /tmp/
mv /tmp/jinja2-* /tmp/jinja2
pushd /tmp/jinja2
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist jinja2
popd
rm -rf /tmp/jinja2

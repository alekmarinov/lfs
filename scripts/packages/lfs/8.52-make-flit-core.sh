#!/bin/bash
set -e
echo "Building flit-core.."

# 8.52. flit-core
# The build backend the other python packages here are built with.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/flit-core.html
#
# BUILD_REQUIRES: 8.51-make-python
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/flit_core
tar -xf /sources/flit_core-*.tar.gz -C /tmp/
mv /tmp/flit_core-* /tmp/flit_core
pushd /tmp/flit_core
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist flit_core
popd
rm -rf /tmp/flit_core

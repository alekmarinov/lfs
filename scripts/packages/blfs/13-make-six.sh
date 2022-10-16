#!/bin/bash
set -e
echo "Building BLFS-six.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 376 KB"

# 13. six
# Python 2 to 3 compatibility library.
# https://www.linuxfromscratch.org/blfs/view/stable/general/python-modules.html#six

tar -xf /sources/six-*.tar.gz -C /tmp/ \
    && mv /tmp/six-* /tmp/six \
    && pushd /tmp/six \
    && pip3 wheel -w dist --no-build-isolation --no-deps $PWD \
    && pip3 install --no-index --find-links dist --no-cache-dir six \
    && popd \
    && rm -rf /tmp/six

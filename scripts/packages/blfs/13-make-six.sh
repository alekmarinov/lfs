#!/bin/bash
# PACKAGE:  six
# SOURCE:   six-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-six.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 376 KB"

# 13. six
# Python 2 to 3 compatibility library.
# https://www.linuxfromscratch.org/blfs/view/12.4/general/python-modules.html#six
#
# NOTE --upgrade. The book installs onto a system which does not have the
# module yet; this build base is cumulative and already carries the previous
# six, so without it pip reports "Requirement already satisfied", installs
# nothing, and the package comes out empty - which build-package.sh then
# refuses, correctly. --no-index keeps it offline regardless.

tar -xf /sources/six-*.tar.gz -C /tmp/ \
    && mv /tmp/six-* /tmp/six \
    && pushd /tmp/six \
    && pip3 wheel -w dist --no-build-isolation --no-deps $PWD \
    && pip3 install --no-index --find-links dist --no-cache-dir --no-user --upgrade six \
    && popd \
    && rm -rf /tmp/six

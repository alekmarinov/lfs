#!/bin/bash
set -e
echo "Building BLFS-mandoc.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 22 MB"

# 9. mandoc
# mandoc is an utility to format manual pages.
# https://www.linuxfromscratch.org/blfs/view/svn/general/mandoc.html

VER=$(ls /sources/mandoc-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/mandoc-*.tar.gz -C /tmp/ \
    && mv /tmp/mandoc-* /tmp/mandoc \
    && pushd /tmp/mandoc \
    && ./configure \
    && make mandoc \
    && if [ $LFS_TEST -eq 1 ]; then make regress || true; fi \
    && install -vm755 mandoc /usr/bin \
    && install -vm644 mandoc.1 /usr/share/man/man1 \
    && popd \
    && rm -rf /tmp/mandoc

#!/bin/bash
set -e
echo "Building DejaGNU.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 6.9 MB"

# 8.17. DejaGNU
# The DejaGnu package contains a framework for running test suites on GNU tools.
# It is written in expect, which itself uses Tcl (Tool Command Language).
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/dejagnu.html

VER=$(ls /sources/dejagnu-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/dejagnu*.tar.gz -C /tmp/ \
    && mv /tmp/dejagnu* /tmp/dejagnu \
    && pushd /tmp/dejagnu \
    && mkdir -v build \
    && cd build \
    && ../configure --prefix=/usr \
    && makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi \
    && makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi \
    && make install \
    && install -v -dm755 /usr/share/doc/dejagnu-$VER \
    && install -v -m644 doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-$VER \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && popd \
    && rm -rf /tmp/dejagnu

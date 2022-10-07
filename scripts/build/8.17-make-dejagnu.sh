#!/bin/bash
set -e
echo "Building DejaGNU.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 6.9 MB"

# 8.17. DejaGNU
VER=$(ls /sources/dejagnu-*.tar.gz | grep -oP "\-[\d.]*" |  sed 's/^.\(.*\).$/\1/')
tar -xf /sources/dejagnu*.tar.gz -C /tmp/ \
    && mv /tmp/dejagnu* /tmp/dejagnu \
    && pushd /tmp/dejagnu \
    && mkdir -v build \
    && cd build \
    && ../configure --prefix=/usr \
    && makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi \
    && makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi \
    && make install \
    && install -v -dm755  /usr/share/doc/dejagnu-$VER \
    && install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-$VER \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && popd \
    && rm -rf /tmp/dejagnu

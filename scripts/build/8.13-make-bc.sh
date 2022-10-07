#!/bin/bash
set -e
echo "Building Bc.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 3.7 MB"

# 8.13. Bc-6.0.1
tar -xf /sources/bc-*.tar.gz -C /tmp/ \
  && mv /tmp/bc-* /tmp/bc \
  && pushd /tmp/bc \
  && CC=gcc ./configure --prefix=/usr -G -O3 -r \
  && make \
  && if [ $LFS_TEST -eq 1 ]; then make test; fi \
  && make install \
  && popd \
  && rm -rf /tmp/bc

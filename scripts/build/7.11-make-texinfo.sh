#!/bin/bash
set -e
echo "Building texinfo.."
echo "Approximate build time: 1.1 SBU"
echo "Required disk space: 128 MB"

# 6.76. Texinfo package contains programs for reading, writing,
# and converting info pages
tar -xf /sources/texinfo-*.tar.xz -C /tmp/ \
  && mv /tmp/texinfo-* /tmp/texinfo \
  && pushd /tmp/texinfo \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && popd \
  && rm -rf /tmp/texinfo

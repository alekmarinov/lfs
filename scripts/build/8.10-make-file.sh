#!/bin/bash
set -e
echo "Building file.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 16 MB"

# 8.10. File-5.42
tar -xf /sources/file-*.tar.gz -C /tmp/ \
  && mv /tmp/file-* /tmp/file \
  && pushd /tmp/file \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && popd \
  && rm -rf /tmp/file

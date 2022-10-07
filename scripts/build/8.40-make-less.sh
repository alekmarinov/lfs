#!/bin/bash
set -e
echo "Building less.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 4.2 MB"

# 6.63. Less package contains a text file viewer
tar -xf /sources/less-*.tar.gz -C /tmp/ \
    && mv /tmp/less-* /tmp/less \
    && pushd /tmp/less \
    && ./configure --prefix=/usr --sysconfdir=/etc \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/less

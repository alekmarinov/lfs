#!/bin/bash
set -e
echo "Building Iana-Etc.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 4.8 MB"

# 8.4. Iana-Etc
# The Iana-Etc package provides data for network services and protocols.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/iana-etc.html

tar -xf /sources/iana-etc-*.tar.gz -C /tmp/ \
    && mv /tmp/iana-etc-* /tmp/iana-etc \
    && pushd /tmp/iana-etc \
    && cp -v services protocols /etc \
    && popd \
    && rm -rf /tmp/iana-etc

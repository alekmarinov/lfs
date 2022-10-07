#!/bin/bash
set -e
echo "Building Psmisc.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 5.8 MB"

# 8.30. Psmisc
# The Psmisc package contains programs for displaying information about running processes.
tar -xf /sources/psmisc-*.tar.xz -C /tmp/ \
    && mv /tmp/psmisc-* /tmp/psmisc \
    && pushd /tmp/psmisc \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/psmisc

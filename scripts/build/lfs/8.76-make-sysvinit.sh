#!/bin/bash
set -e
echo "Building sysvinit.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 2.7 MB"

# 8.76. Sysvinit
# The Sysvinit package contains programs for controlling the startup, running, and shutdown of the system.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/sysvinit.html

tar -xf /sources/sysvinit-*.tar.xz -C /tmp/ \
    && mv /tmp/sysvinit-* /tmp/sysvinit \
    && pushd /tmp/sysvinit \
    && patch -Np1 -i $(ls /sources/sysvinit-*-consolidated-1.patch) \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/sysvinit

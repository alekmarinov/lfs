#!/bin/bash
set -e
echo "Building LFS-Bootscripts.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 244 KB"

# 9.2. LFS-Bootscripts
# The LFS-Bootscripts package contains a set of scripts to start/stop
# the LFS system at bootup/shutdown. The configuration files and procedures
# needed to customize the boot process are described in the following sections.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter09/bootscripts.html

tar -xf /sources/lfs-bootscripts-*.tar.xz -C /tmp/ \
    && mv /tmp/lfs-bootscripts-* /tmp/lfs-bootscripts \
    && pushd /tmp/lfs-bootscripts \
    && make install \
    && popd \
    && rm -rf /tmp/lfs-bootscripts

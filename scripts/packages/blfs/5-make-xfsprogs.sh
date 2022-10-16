#!/bin/bash
set -e
echo "Building BLFS-xfsprogs.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 52 MB"

# 5. xfsprogs
# The xfsprogs package contains administration and debugging tools for the XFS file system.
# required: inih,liburcu
# optional: ICU - for unicode name scanning in xfs_scrub
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/xfsprogs.html

# Kernel config:
# ------------------------------------------------------------------------
# File systems --->
#   <*/M> XFS filesystem support [CONFIG_XFS_FS]

VER=$(ls /sources/xfsprogs-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/xfsprogs-*.tar.xz -C /tmp/ \
    && mv /tmp/xfsprogs-* /tmp/xfsprogs \
    && pushd /tmp/xfsprogs \
    && make DEBUG=-DNDEBUG INSTALL_USER=root INSTALL_GROUP=root \
    && make PKG_DOC_DIR=/usr/share/doc/xfsprogs-$VER install \
    && make PKG_DOC_DIR=/usr/share/doc/xfsprogs-$VER install-dev \
    && rm -rfv /usr/lib/libhandle.{a,la} \
    && popd \
    && rm -rf /tmp/xfsprogs

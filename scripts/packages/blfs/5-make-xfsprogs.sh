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
#
# NOTE the sed on po/de.po fixes an upstream typo: the German string writes
# the float as '%.lf' with a letter l where the original has '%.1f' with a
# digit one. msgfmt in 12.4 rejects a translation whose format specifiers do
# not match the original, where the older one let it through.
#
# NOTE xfsprogs calls ICU's u_init() and u_cleanup() without including
# <unicode/uclean.h>, so they are implicit declarations. The symbols do
# exist in libicuuc and the link succeeds; it is only that GCC 14 turned
# implicit declarations from a warning into an error. CFLAGS is set in the
# environment rather than passed to make so that the configure step
# xfsprogs runs from its own Makefile picks it up too.

# Kernel config:
# ------------------------------------------------------------------------
# File systems --->
#   <*/M> XFS filesystem support [CONFIG_XFS_FS]

VER=$(ls /sources/xfsprogs-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/xfsprogs-*.tar.xz -C /tmp/ \
    && mv /tmp/xfsprogs-* /tmp/xfsprogs \
    && pushd /tmp/xfsprogs \
    && sed -i 's/%\.lf Megabytes/%.1f Megabytes/' po/de.po \
    && CFLAGS="-Wno-error=implicit-function-declaration" \
       make DEBUG=-DNDEBUG INSTALL_USER=root INSTALL_GROUP=root \
    && make PKG_DOC_DIR=/usr/share/doc/xfsprogs-$VER install \
    && make PKG_DOC_DIR=/usr/share/doc/xfsprogs-$VER install-dev \
    && rm -rfv /usr/lib/libhandle.{a,la} \
    && popd \
    && rm -rf /tmp/xfsprogs

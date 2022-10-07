#!/bin/bash
set -e
echo "Building Acl.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 6.1 MB"

# 8.23. Acl
# The Acl package contains utilities to administer Access Control Lists,
# which are used to define more fine-grained discretionary access rights
# for files and directories.
VER=$(ls /sources/acl-*.tar.xz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/acl-*.tar.gz -C /tmp/ \
    && mv /tmp/acl-* /tmp/acl \
    && pushd /tmp/acl \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/acl-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/acl

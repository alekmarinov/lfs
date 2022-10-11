#!/bin/bash
set -e
echo "Building BLFS-rpcsvc-proto.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 2.1 MB"

# 17. rpcsvc-proto
# The rpcsvc-proto package contains the rcpsvc protocol files and headers,
# formerly included with glibc, that are not included in replacement libtirpc, 
# along with the rpcgen program.
# https://www.linuxfromscratch.org/blfs/view/stable/general/sharutils.html

tar -xf /sources/rpcsvc-proto-*.tar.xz -C /tmp/ \
    && mv /tmp/rpcsvc-proto-* /tmp/rpcsvc-proto \
    && pushd /tmp/rpcsvc-proto \
    && ./configure \
        --sysconfdir=/etc \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/rpcsvc-proto

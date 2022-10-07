#!/bin/bash
set -e
echo "Building Libcap.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 2.7 MB"

# 8.24. Libcap
# The Libcap package implements the user-space interfaces to the
# POSIX 1003.1e capabilities available in Linux kernels. These capabilities
# are a partitioning of the all powerful root privilege into a set of distinct privileges.
tar -xf /sources/libcap-*.tar.xz -C /tmp/ \
    && mv /tmp/libcap-* /tmp/libcap \
    && pushd /tmp/libcap \
    && sed -i '/install -m.*STA/d' libcap/Makefile \
    && make prefix=/usr lib=lib \
    && if [ $LFS_TEST -eq 1 ]; then make test; fi \
    && make prefix=/usr lib=lib install \
    && popd \
    && rm -rf /tmp/libcap

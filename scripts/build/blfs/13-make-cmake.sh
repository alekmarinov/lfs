#!/bin/bash
set -e
echo "Building BLFS-cmake.."
echo "Approximate build time: 2.3 SBU"
echo "Required disk space: 417 MB"

# 13. cmake
# The CMake package contains a modern toolset used for generating Makefiles. 
# required: libuv
# recommended: curl,libarchive,nghttp2
# https://www.linuxfromscratch.org/blfs/view/stable/general/cmake.html

VER=$(ls /sources/cmake-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/cmake-*.tar.gz -C /tmp/ \
    && mv /tmp/cmake-* /tmp/cmake \
    && pushd /tmp/cmake \
    && patch -Np1 -i /sources/cmake-$VER-upstream_fix-1.patch \
    && sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake \
    && ./bootstrap \
        --prefix=/usr \
        --system-libs \
        --mandir=/share/man \
        --no-system-jsoncpp \
        --no-system-librhash \
        --docdir=/share/doc/cmake-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/cmake

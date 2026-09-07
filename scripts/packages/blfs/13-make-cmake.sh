#!/bin/bash
# PACKAGE:  cmake
# SOURCE:   cmake-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-cmake.."
echo "Approximate build time: 2.3 SBU"
echo "Required disk space: 417 MB"

# 13. cmake
# The CMake package contains a modern toolset used for generating Makefiles. 
# required: libuv
# recommended: curl,libarchive,nghttp2
# https://www.linuxfromscratch.org/blfs/view/12.4/general/cmake.html
#
# NOTE --no-system-cppdap is new here, and cmake 4 is why. cppdap did not exist
# in 3.24, so --system-libs had nothing to switch on; in 4.1 it does, and there
# is no cppdap installed. The failure names the wrong library: system cppdap
# links system jsoncpp, so enabling it turns CMAKE_USE_SYSTEM_JSONCPP back on
# and the error reads "CMAKE_USE_SYSTEM_JSONCPP is ON but a JsonCpp is not
# found" even though --no-system-jsoncpp was passed and did apply. The cache
# is what says so: JSONCPP=OFF, CPPDAP=ON.

VER=$(ls /sources/cmake-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
# Cleared first, the way 33 other recipes here already do it. Without it,
# 'mv /tmp/cmake-4.1.0 /tmp/cmake' moves the tree INSIDE an existing
# /tmp/cmake instead of renaming it, pushd then succeeds into a directory
# holding nothing but cmake-4.1.0/, and the first sed fails on a path that is
# one level too shallow. The stale /tmp/cmake came from the base: copy-or-del.sh
# copies /tmp along with everything else, so a build tree left behind by an
# earlier package becomes permanent.
rm -rf /tmp/cmake
tar -xf /sources/cmake-*.tar.gz -C /tmp/ \
    && mv /tmp/cmake-* /tmp/cmake \
    && pushd /tmp/cmake \
    && sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake \
    && ./bootstrap \
        --prefix=/usr \
        --system-libs \
        --mandir=/share/man \
        --no-system-jsoncpp \
        --no-system-cppdap \
        --no-system-librhash \
        --docdir=/share/doc/cmake-$VER \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/cmake

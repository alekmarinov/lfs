#!/bin/bash
# PACKAGE:  spirv-tools
# SOURCE:   SPIRV-Tools-vulkan-sdk-*.tar.gz
# VERSION:  1.4.321.0
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-SPIRV-Tools.."

# SPIRV-Tools
# Assembler, disassembler, validator and optimiser for SPIR-V. Mesa requires
# it whenever with_clc is on, which the iris driver turns on.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/spirv-tools.html
#
# NOTE SPIRV-Headers_SOURCE_DIR=/usr points it at the installed headers rather
# than a sibling source checkout, which is how upstream expects to find them.
#
# BUILD_REQUIRES: 13-make-spirv-headers 13-make-cmake 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/spirv-tools
tar -xf /sources/SPIRV-Tools-vulkan-sdk-*.tar.gz -C /tmp/
mv /tmp/SPIRV-Tools-vulkan-sdk-* /tmp/spirv-tools
pushd /tmp/spirv-tools
mkdir build
cd build
cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release \
      -D SPIRV_WERROR=OFF \
      -D BUILD_SHARED_LIBS=ON \
      -D SPIRV_TOOLS_BUILD_STATIC=OFF \
      -D SPIRV-Headers_SOURCE_DIR=/usr \
      -G Ninja ..
ninja
ninja install
popd
rm -rf /tmp/spirv-tools

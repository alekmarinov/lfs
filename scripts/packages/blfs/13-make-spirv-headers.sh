#!/bin/bash
# PACKAGE:  spirv-headers
# SOURCE:   SPIRV-Headers-vulkan-sdk-*.tar.gz
# VERSION:  1.4.321.0
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-SPIRV-Headers.."

# SPIRV-Headers
# Machine-readable SPIR-V grammar and headers. Header-only; SPIRV-Tools and
# SPIRV-LLVM-Translator both compile against it.
#
# Part of the chain mesa 25 needs for the Intel iris gallium driver: iris puts
# mesa into its 'with_clc' mode, which requires libclc, LLVMSPIRVLib and
# SPIRV-Tools. Mesa 22 needed none of it.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/spirv-headers.html
#
# BUILD_REQUIRES: 13-make-cmake 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/spirv-headers
tar -xf /sources/SPIRV-Headers-vulkan-sdk-*.tar.gz -C /tmp/
mv /tmp/SPIRV-Headers-vulkan-sdk-* /tmp/spirv-headers
pushd /tmp/spirv-headers
mkdir build
cd build
cmake -D CMAKE_INSTALL_PREFIX=/usr -G Ninja ..
ninja
ninja install
popd
rm -rf /tmp/spirv-headers

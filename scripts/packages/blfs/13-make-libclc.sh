#!/bin/bash
# PACKAGE:  libclc
# SOURCE:   libclc-*.src.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libclc.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 250 MB"

# libclc
# The OpenCL C library llvm compiles device code against.
#
# Needed by mesa 25, and only because of the drivers chosen here. mesa's
# meson.build computes 'with_driver_using_cl' from the enabled drivers, and
# iris - the Intel Gen8+ gallium driver - is in that list, so configure stops
# with:
#   ERROR: Dependency "libclc" not found, tried pkgconfig and cmake
# Mesa 22 did not ask for it. The alternative was dropping iris, which would
# quietly cost Intel GPU support on real hardware, so the dependency is built
# instead.
#
# The version tracks llvm: it ships in the same llvm-project release and is
# compiled by that clang, so it is 20.1.8 here because llvm is.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/libclc.html
#
# BUILD_REQUIRES: 13-make-llvm 13-make-cmake 8.56-make-ninja 7.10-make-python
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

# This must be built AFTER SPIRV-LLVM-Translator, and the check below is not
# optional politeness - it is the difference between a working mesa and a
# silent miscompile.
#
# libclc's CMakeLists says:
#   # spirv-mesa3d and spirv64-mesa3d targets can only be built with the
#   # (optional) llvm-spirv external tool.
#   if( llvm-spirv_exe )
# Without llvm-spirv on PATH it builds the AMD and R600 bitcode only, installs
# 126 files, and exits 0. Nothing complains. mesa then configures fine, gets
# most of the way through compiling, and mesa_clc dies with signal 11 while
# generating the Intel shader SPIR-V, with no message at all - because the
# spirv64-mesa3d bitcode it wants was never built.
#
# That is exactly what happened here once: libclc was built 15 minutes before
# the translator existed. Failing loudly is cheaper than diagnosing it again.
command -v llvm-spirv > /dev/null || {
    echo "llvm-spirv not found - build 13-make-spirv-llvm-translator first."
    echo "Without it libclc silently omits the spirv-mesa3d targets mesa needs."
    exit 1
}

VER=$(basename "$(ls /sources/libclc-[0-9]*.src.tar.xz)" .src.tar.xz | sed 's/^libclc-//')
rm -rf /tmp/libclc
tar -xf /sources/libclc-[0-9]*.src.tar.xz -C /tmp/
mv /tmp/libclc-$VER.src /tmp/libclc
pushd /tmp/libclc
mkdir build
cd build
cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release \
      -G Ninja ..
ninja
ninja install

# Proof that the spirv targets were actually produced, not just that cmake
# exited 0.
#
# NOTE the extension is .spv, not .bc. The AMD and nvptx targets install LLVM
# bitcode; the two spirv-mesa3d targets install SPIR-V modules, which is the
# whole point of them. Checking for .bc here was wrong and failed a build that
# had in fact worked.
ls /usr/share/clc/spirv64-mesa3d-.spv > /dev/null || {
    echo "libclc installed no spirv64-mesa3d module - mesa_clc will segfault."
    echo "That means llvm-spirv was not found when cmake ran."
    exit 1
}

popd
rm -rf /tmp/libclc

#!/bin/bash
set -e
echo "Building BLFS-llvm.."
echo "Approximate build time: 0.5 SBU"
echo "Required disk space: 382 MB"

# 13. valgrind
# The LLVM package contains a collection of modular and reusable compiler
# and toolchain technologies. The Low Level Virtual Machine 
# (LLVM) Core libraries provide a modern source and target-independent optimizer,
# along with code generation support for many popular CPUs.
# These libraries are built around a well specified code representation known as
# the LLVM intermediate representation ("LLVM IR").
# requires: cmake
# https://www.linuxfromscratch.org/blfs/view/stable/general/llvm.html

# FIXME: docs

COMPILER_RT_VER=$(ls /sources/compiler-rt-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/llvm-*.tar.xz -C /tmp/ \
    && mv /tmp/llvm-* /tmp/llvm \
    && pushd /tmp/llvm \
    && tar -xf /sources/clang-*.tar.xz -C tools \
    && mv tools/clang-* tools/clang \
    && tar -xf /sources/compiler-rt-*.tar.xz -C projects \
    && mv projects/compiler-rt-* projects/compiler-rt \
    && grep -rl '#!.*python' | xargs sed -i '1s/python$/python3/' \
    && patch -Np2 -d projects/compiler-rt < /sources/compiler-rt-$COMPILER_RT_VER-glibc_2_36-1.patch \
    && mkdir -v build \
    && cd build \
    && CC=gcc CXX=g++ cmake \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DLLVM_ENABLE_FFI=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_BUILD_LLVM_DYLIB=ON \
        -DLLVM_LINK_LLVM_DYLIB=ON \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_TARGETS_TO_BUILD="host;AMDGPU;BPF" \
        -DLLVM_BINUTILS_INCDIR=/usr/include \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -Wno-dev -G Ninja .. \
    && ninja \
    && ninja install \
    && popd \
    && rm -rf /tmp/llvm

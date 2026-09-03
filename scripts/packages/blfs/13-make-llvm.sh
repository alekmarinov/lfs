#!/bin/bash
# PACKAGE:  llvm
# SOURCE:   llvm-*.src.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-llvm.."
echo "Approximate build time: 33 SBU"
echo "Required disk space: 3.1 GB"

# 13. valgrind
# The LLVM package contains a collection of modular and reusable compiler
# and toolchain technologies. The Low Level Virtual Machine 
# (LLVM) Core libraries provide a modern source and target-independent optimizer,
# along with code generation support for many popular CPUs.
# These libraries are built around a well specified code representation known as
# the LLVM intermediate representation ("LLVM IR").
# requires: cmake
# optional: doxygen,git,graphviz,libxml2,pygments,rsync(for tests),
#           texlive/install-tl-unx,valgrind,pyyaml,zip
# https://www.linuxfromscratch.org/blfs/view/stable/general/llvm.html
#
# NOTE compiler-rt is not built. It is the sanitizer runtime, and nothing here
# uses it: rust wants llvm-config and firefox wants clang. Version 14 of it
# does not compile against glibc 2.42 - it measures the 'struct termio' that
# glibc removed, and its own -ffreestanding build flag leaves stdlib.h
# declaring nothing, so dfsan loses malloc and strtol. Those are its flags to
# choose, not something a caller can correct from outside.
#
# NOTE -include cstdint. LLVM 14 reaches uint64_t through headers that
# libstdc++ used to pull in for free and no longer does, so SmallVector.h fails
# with 'uint64_t was not declared'. Forcing that one header into every
# translation unit fixes every such site at once.

VER=$(ls /sources/llvm-*.src.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/llvm-*.tar.xz -C /tmp/ \
    && mv /tmp/llvm-* /tmp/llvm \
    && pushd /tmp/llvm \
    && tar -xf /sources/clang-*.tar.xz -C tools \
    && mv tools/clang-* tools/clang \
    && grep -rl '#!.*python' | xargs sed -i '1s/python$/python3/' \
    && mkdir -v build \
    && cd build \
    && CC=gcc CXX=g++ cmake \
        -DCMAKE_CXX_FLAGS="-include cstdint" \
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
    && if [ $LFS_DOCS -eq 1 ]; then \
        cmake \
            -DLLVM_BUILD_DOCS=ON \
            -DLLVM_ENABLE_SPHINX=ON \
            -DSPHINX_WARNINGS_AS_ERRORS=OFF \
            -Wno-dev -G Ninja .. \
        && ninja docs-llvm-html docs-llvm-man; \
        ninja docs-clang-html docs-clang-man;
    fi \
    && if [ $LFS_TEST -eq 1 ]; then ninja check-all || true; fi \
    && ninja install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -d -m755 /usr/share/doc/llvm-$VER \
        && mv -v /usr/share/doc/llvm/html /usr/share/doc/llvm-$VER/llvm-html \
        && rmdir -v /usr/share/doc/llvm; \
    fi \
    && popd \
    && rm -rf /tmp/llvm

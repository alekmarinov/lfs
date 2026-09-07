#!/bin/bash
# PACKAGE:  llvm
# SOURCE:   llvm-[0-9]*.src.tar.xz
# VERSION:  20.1.8
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
# https://www.linuxfromscratch.org/blfs/view/12.4/general/llvm.html
#
# NOTE compiler-rt is not built. It is the sanitizer runtime and nothing here
# uses it: rust wants llvm-config and firefox wants clang. It was excluded on
# llvm 14 because that version would not compile against glibc 2.42; the
# exclusion is kept because the reason to include it never existed.
#
# NOTE llvm 20 is split across three tarballs. What used to be one archive is
# now llvm-<v>.src plus llvm-cmake-<v>.src and llvm-third-party-<v>.src, and
# the build looks for those two at ../cmake and ../third-party - paths which
# only exist in a full monorepo checkout. They are unpacked inside the source
# tree instead and the two references are pointed at where they landed, which
# is what the book does.
#
# The globs are pinned to [0-9] and to $VER for the same reason: 'llvm-*' also
# matches llvm-cmake- and llvm-third-party-, and tar takes the first match as
# the archive and the rest as member names to extract from it - which is what
# "Not found in archive" meant.

VER=$(ls /sources/llvm-[0-9]*.src.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
rm -rf /tmp/llvm
tar -xf /sources/llvm-[0-9]*.src.tar.xz -C /tmp/ \
    && mv /tmp/llvm-[0-9]* /tmp/llvm \
    && pushd /tmp/llvm \
    && tar -xf /sources/llvm-cmake-$VER.src.tar.xz \
    && tar -xf /sources/llvm-third-party-$VER.src.tar.xz \
    && sed "/LLVM_COMMON_CMAKE_UTILS/s@../cmake@cmake-$VER.src@" -i CMakeLists.txt \
    && sed "/LLVM_THIRD_PARTY_DIR/s@../third-party@third-party-$VER.src@" \
           -i cmake/modules/HandleLLVMOptions.cmake \
    && tar -xf /sources/clang-$VER.src.tar.xz -C tools \
    && mv tools/clang-$VER.src tools/clang \
    && grep -rl '#!.*python' | xargs sed -i '1s/python$/python3/' \
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

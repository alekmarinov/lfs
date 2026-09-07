#!/bin/bash
# PACKAGE:  spirv-llvm-translator
# SOURCE:   SPIRV-LLVM-Translator-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-SPIRV-LLVM-Translator.."

# SPIRV-LLVM-Translator
# Converts between LLVM IR and SPIR-V. This is the LLVMSPIRVLib that mesa 25
# looks for:
#   ERROR: Dependency "LLVMSPIRVLib" not found, tried pkgconfig and cmake
#
# Its version has to track llvm closely: mesa requires
#   >= <llvm major>.<llvm minor>  and  < <llvm major>.<llvm minor + 1>
# so with llvm 20.1.8 the accepted range is >= 20.1 and < 20.2, which 20.1.5
# satisfies. Bumping llvm means bumping this in step.
#
# NOTE BUILD_SHARED_LIBS=OFF, where the book uses ON. This is deliberate and
# it fixes a crash that is otherwise very hard to read.
#
# mesa here is built with -Dshared-llvm=disabled, so that llvm stays a build
# dependency rather than adding 235 MB to every image. mesa_clc therefore
# links llvm's static component libraries directly. If this package is shared,
# it drags in libLLVM.so as well - and mesa_clc then holds TWO complete copies
# of llvm, the static one inside it and the shared one behind this library.
# Both register exit handlers, both tear down the same state, and the process
# dies in _int_free_merge_chunk with a corrupted arena pointer during
# _dl_fini - after main has already returned 0 and written correct output.
# ninja sees exit 267 and stops, 700 steps into the mesa build.
#
# Built static, mesa_clc has one llvm and exits cleanly. The alternative -
# flipping mesa to shared-llvm - also works but forfeits the size decision,
# because the runtime driver would then link libLLVM.so too. Only the
# build-time tool needs SPIR-V at all.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/spirv-llvm-translator.html
#
# BUILD_REQUIRES: 13-make-spirv-tools 13-make-llvm 9-make-libxml2 13-make-cmake 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/spirv-llvm-translator
tar -xf /sources/SPIRV-LLVM-Translator-*.tar.gz -C /tmp/
mv /tmp/SPIRV-LLVM-Translator-* /tmp/spirv-llvm-translator
pushd /tmp/spirv-llvm-translator
mkdir build
cd build
cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release \
      -D BUILD_SHARED_LIBS=OFF \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D LLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR=/usr \
      -G Ninja ..
ninja

# The shared library from any previous build of this package has to go before
# installing, or nothing changes.
#
# The build base is cumulative, so a libLLVMSPIRVLib.so left by an earlier
# BUILD_SHARED_LIBS=ON build stays there when this one installs only the .a -
# and the linker prefers the .so. mesa_clc then links the shared library
# again, gets its second copy of llvm, and crashes exactly as before, while
# the package looks correctly built. Removed here rather than by hand so the
# deletion is recorded as a whiteout in .meta/removed and an upgrading system
# drops it too.
rm -f /usr/lib/libLLVMSPIRVLib.so /usr/lib/libLLVMSPIRVLib.so.*

ninja install

# and prove the shared one did not come back
if [ -e /usr/lib/libLLVMSPIRVLib.so ]; then
    echo "libLLVMSPIRVLib.so still present - mesa_clc will link two llvms and crash."
    exit 1
fi
popd
rm -rf /tmp/spirv-llvm-translator

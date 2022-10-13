#!/bin/bash
set -e
echo "Building BLFS-doxygen.."
echo "Approximate build time: 1.4 SBU"
echo "Required disk space: 214 MB"

# 13. doxygen
# The Doxygen package contains a documentation system for C++, C, Java, Objective-C, Corba IDL and to some extent PHP, C# and D.
# required: cmake,git
# optional: graphviz,ghostscript,libxml2(for tests),llvm,python2,
#           qt-5(for doxywizard),texlive(or install-tl-unx),
#           xapian(for doxyindexer),javacc
# https://www.linuxfromscratch.org/blfs/view/svn/general/doxygen.html

VER=$(ls /sources/doxygen-*.src.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/doxygen-*.src.tar.gz -C /tmp/ \
    && mv /tmp/doxygen-* /tmp/doxygen \
    && pushd /tmp/doxygen \
    && mkdir -v build \
    && cd build \
    && cmake \
        -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -Wno-dev .. \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make test || true; fi \
    && if [ $LFS_DOCS -eq 1 ]; then \
        cmake -DDOC_INSTALL_DIR=share/doc/doxygen-$VER -Dbuild_doc=ON .. \
        && make docs; \
    fi \
    && make install \
    && popd \
    && rm -rf /tmp/doxygen

#!/bin/bash
set -e
echo "Building BLFS-popt.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 6.9 MB"

# 9. popt
# The popt package contains the popt libraries which are used by some programs to parse command-line options.
# https://www.linuxfromscratch.org/blfs/view/svn/general/popt.html

VER=$(ls /sources/popt-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/popt-*.tar.gz -C /tmp/ \
    && mv /tmp/popt-* /tmp/popt \
    && pushd /tmp/popt \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make \
    && if [ $LFS_DOCS -eq 1 ]; then \
        sed -i 's@\./@src/@' Doxyfile; \
        doxygen; \
    fi \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -m755 -d /usr/share/doc/popt-$VER; \
        install -v -m644 doxygen/html/* /usr/share/doc/popt-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/popt

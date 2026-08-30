#!/bin/bash
set -e
echo "Building glibc.."
echo "Approximate build time: 4.4 SBU"
echo "Required disk space: 821 MB"

# 5.5. Glibc
# The Glibc package contains the main C library. This library provides the 
# basic routines for allocating memory, searching directories, opening and
# closing files, reading and writing files, string handling, pattern matching,
# arithmetic, and so on.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter05/glibc.html
#
# NOTE libc_cv_cxx_link_ok=no is passed on purpose. gcc pass 1 is built --disable-shared
# and --disable-libstdcxx, so there is no libstdc++ and no libgcc_s - but it
# does install the C++ headers, so glibc's probes compile, it keeps CXX, and
# support/Makefile then picks links-dso-program, which links -lstdc++ -lgcc_s
# and fails.
#
# glibc has a check for this - "whether the C++ compiler can link programs" -
# whose answer it caches in libc_cv_cxx_link_ok. Setting that to no is the
# supported way to say there is no usable C++ here, and glibc then builds
# links-dso-program-c, which needs only -lgcc. Passing CXX= empty does not
# work: autoconf treats an empty value as unset and finds the compiler again.
#
# NOTE what 12.4 changed: --with-headers is gone, --disable-nscd is new,
# --enable-kernel moved from 3.2 to 5.4, and the mkheaders step at the end
# was dropped - gcc pass 1 writes a complete limits.h itself now.

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS_BASE/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS_BASE/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS_BASE/lib64/ld-lsb-x86-64.so.3
    ;;
esac

GCC_VER=$(ls /$LFS_BASE/sources/gcc-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
rm -rf /tmp/glibc \
    && tar -xf $LFS_BASE/sources/glibc-*.tar.xz -C /tmp/ \
    && mv /tmp/glibc-* /tmp/glibc \
    && pushd /tmp/glibc \
    && patch -Np1 -i $(ls $LFS_BASE/sources/glibc-*-fhs-1.patch) \
    && mkdir -v build \
    && cd build \
    && echo "rootsbindir=/usr/sbin" > configparms \
    && ../configure \
        libc_cv_cxx_link_ok=no \
        --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(../scripts/config.guess) \
        --disable-nscd \
        --enable-kernel=5.4 \
        libc_cv_slibdir=/usr/lib \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && sed '/RTLDLIST=/s@/usr@@g' -i $LFS_BASE/usr/bin/ldd \
    && echo 'int main(){}' | gcc -xc - \
    && readelf -l a.out | grep ld-linux \
    && rm -v a.out \
    && popd \
    && rm -rf /tmp/glibc

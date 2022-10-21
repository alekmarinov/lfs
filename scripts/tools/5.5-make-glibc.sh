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
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter05/glibc.html

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS_BASE/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS_BASE/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS_BASE/lib64/ld-lsb-x86-64.so.3
    ;;
esac

GCC_VER=$(ls /$LFS_BASE/sources/gcc-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
rm -rf /tmp/glibc \
    && tar -xf glibc-*.tar.xz -C /tmp/ \
    && mv /tmp/glibc-* /tmp/glibc \
    && pushd /tmp/glibc \
    && patch -Np1 -i $(ls $LFS_BASE/sources/glibc-*-fhs-1.patch) \
    && mkdir -v build \
    && cd build \
    && echo "rootsbindir=/usr/sbin" > configparms \
    && ../configure \
        --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(../scripts/config.guess) \
        --enable-kernel=3.2 \
        --with-headers=$LFS_BASE/usr/include \
        libc_cv_slibdir=/usr/lib \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && sed '/RTLDLIST=/s@/usr@@g' -i $LFS_BASE/usr/bin/ldd \
    && echo 'int main(){}' | gcc -xc - \
    && readelf -l a.out | grep ld-linux \
    && rm -v a.out \
    && "$LFS_BASE/tools/libexec/gcc/$LFS_TGT/$GCC_VER/install-tools/mkheaders" \
    && popd \
    && rm -rf /tmp/glibc

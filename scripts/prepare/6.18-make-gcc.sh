#!/bin/bash
set -e
echo "Building gcc.."
echo "Approximate build time: 15 SBU"
echo "Required disk space: 4.5 GB"

# 6.18. GCC
# The GCC package contains the GNU compiler collection, which includes the C and C++ compilers.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/gcc-pass2.html

tar -xf gcc-*.tar.xz -C /tmp/ \
    && mv /tmp/gcc-* /tmp/gcc \
    && pushd /tmp/gcc \
    && tar -xf $LFS/sources/mpfr-*.tar.xz \
    && mv -v mpfr-* mpfr \
    && tar -xf $LFS/sources/gmp-*.tar.xz \
    && mv -v gmp-* gmp \
    && tar -xf $LFS/sources/mpc-*.tar.gz \
    && mv -v mpc-* mpc \
    && case $(uname -m) in \
        x86_64) \
        sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 \
        ;; \
    esac \
    && sed '/thread_header =/s/@.*@/gthr-posix.h/' \
        -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in \
    && mkdir -v build \
    && cd build \
    && ../configure \
        --build=$(../config.guess) \
        --host=$LFS_TGT \
        --target=$LFS_TGT \
        LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
        --prefix=/usr \
        --with-build-sysroot=$LFS \
        --enable-initfini-array \
        --disable-nls \
        --disable-multilib \
        --disable-decimal-float \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --enable-languages=c,c++ \
    && make \
    && make DESTDIR=$LFS install \
    && ln -sv gcc $LFS/usr/bin/cc \
    && popd \
    && rm -rf /tmp/gcc

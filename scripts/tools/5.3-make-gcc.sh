#!/bin/bash
set -e
echo "Building gcc.."
echo "Approximate build time: 12 SBU"
echo "Required disk space: 3.8 GB"

# 5.3. GCC
# The GCC package contains the GNU compiler collection, which includes the C and C++ compilers.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter05/gcc-pass1.html

rm -rf /tmp/gcc \
    && tar -xf $LFS_BASE/sources/gcc-*.tar.xz -C /tmp/ \
    && mv /tmp/gcc-* /tmp/gcc \
    && pushd /tmp/gcc \
    && tar -xf $LFS_BASE/sources/mpfr-*.tar.xz \
    && mv -v mpfr-* mpfr \
    && tar -xf $LFS_BASE/sources/gmp-*.tar.xz \
    && mv -v gmp-* gmp \
    && tar -xf $LFS_BASE/sources/mpc-*.tar.gz \
    && mv -v mpc-* mpc \
    && case $(uname -m) in \
        x86_64) \
        sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 \
        ;; \
    esac \
    && mkdir -v build \
    && cd build \
    && ../configure               \
        --target=$LFS_TGT         \
        --prefix=$LFS_BASE/tools       \
        --with-glibc-version=2.36 \
        --with-sysroot=$LFS_BASE       \
        --with-newlib             \
        --without-headers         \
        --disable-nls             \
        --disable-shared          \
        --disable-multilib        \
        --disable-decimal-float   \
        --disable-threads         \
        --disable-libatomic       \
        --disable-libgomp         \
        --disable-libquadmath     \
        --disable-libssp          \
        --disable-libvtv          \
        --disable-libstdcxx       \
        --enable-languages=c,c++  \
    && make \
    && make install \
    && cd .. \
    && cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
        `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h \
    && popd \
    && rm -rf /tmp/gcc

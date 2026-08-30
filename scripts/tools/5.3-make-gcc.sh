#!/bin/bash
set -e
echo "Building gcc.."
echo "Approximate build time: 12 SBU"
echo "Required disk space: 3.8 GB"

# 5.3. GCC
# The GCC package contains the GNU compiler collection, which includes the C and C++ compilers.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter05/gcc-pass1.html
#
# NOTE the full internal limits.h is written to include/, not to
# install-tools/include/ as it was through 11.2. Writing it to the old
# path leaves gcc using its stub header, and nothing complains until the
# first package which includes a glibc header - m4, here - stops with
# '#error "Assumed value of MB_LEN_MAX wrong"', which says nothing about
# where the real problem is.

GLIBC_VER=$(ls $LFS_BASE/sources/glibc-*.tar.xz \
    | sed 's|.*/glibc-||; s|\.tar\.xz$||')

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
        --with-glibc-version=$GLIBC_VER \
        --with-sysroot=$LFS_BASE       \
        --with-newlib             \
        --without-headers         \
        --enable-default-pie      \
        --enable-default-ssp      \
        --disable-nls             \
        --disable-shared          \
        --disable-multilib        \
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
        `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h \
    && popd \
    && rm -rf /tmp/gcc

#!/bin/bash
set -e
echo "Building BLFS-grub.."
echo "Approximate build time: 1 SBU"
echo "Required disk space: 137 MB"

# 5. grub
# The GRUB package provides GRand Unified Bootloader. In this page it will be 
# built with UEFI support, which is not enabled for GRUB built in LFS.
# recommended: efibootmgr,freetype2
# optional: lvm2
# https://www.linuxfromscratch.org/blfs/view/svn/postlfs/grub-efi.html

VER=$(ls /sources/grub-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
UNIFONT_VER=$(ls /sources/unifont-*.pcf.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
GCC_VER=$(ls /sources/gcc-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/grub-*.tar.xz -C /tmp/ \
    && mv /tmp/grub-* /tmp/grub \
    && pushd /tmp/grub \
    && mkdir -pv /usr/share/fonts/unifont \
    && gunzip -c /sources/unifont-$UNIFONT_VER.pcf.gz > /usr/share/fonts/unifont/unifont.pcf

case $(uname -m) in i?86 )
    tar xf /sources/gcc-$GCC_VER.tar.xz
    mkdir gcc-$GCC_VER/build
    pushd gcc-$GCC_VER/build
        ../configure \
            --prefix=$PWD/../../x86_64-gcc \
            --target=x86_64-linux-gnu \
            --with-system-zlib \
            --enable-languages=c,c++ \
            --with-ld=/usr/bin/ld
        make all-gcc
        make install-gcc
    popd
    export TARGET_CC=$PWD/x86_64-gcc/bin/x86_64-linux-gnu-gcc
esac

./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --disable-efiemu \
    --enable-grub-mkfont \
    --with-platform=efi \
    --target=x86_64 \
    --disable-werror \
    && unset TARGET_CC \
    && make \
    && make install \
    && mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions \
    && popd \
    && rm -rf /tmp/grub

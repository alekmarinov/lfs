#!/bin/bash
set -e
echo "Building Coreutils.."
echo "Approximate build time: 0.7 SBU"
echo "Required disk space: 139 MB"

# 6.5. Coreutils
# The Coreutils package contains utilities for showing and setting the basic
# system characteristics.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/coreutils.html

tar -xf coreutils-*.tar.xz -C /tmp/ \
    && mv /tmp/coreutils-* /tmp/coreutils \
    && pushd /tmp/coreutils \
    && ./configure \
        --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) \
        --enable-install-program=hostname \
        --enable-no-install-program=kill,uptime \
    && make \
    && make DESTDIR=$LFS install \
    && mv -v $LFS/usr/bin/chroot $LFS/usr/sbin \
    && mkdir -pv $LFS/usr/share/man/man8 \
    && mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8 \
    && sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8 \
    && popd \
    && rm -rf /tmp/coreutils

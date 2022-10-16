#!/bin/bash
set -e
echo "Building Coreutils.."
echo "Approximate build time: 0.7 SBU"
echo "Required disk space: 139 MB"

# 6.5. Coreutils
# The Coreutils package contains utilities for showing and setting the basic
# system characteristics.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/coreutils.html

rm -rf /tmp/coreutils \
    && tar -xf coreutils-*.tar.xz -C /tmp/ \
    && mv /tmp/coreutils-* /tmp/coreutils \
    && pushd /tmp/coreutils \
    && ./configure \
        --prefix=/usr \
        --host=$LFS_TGT \
        --build=$(build-aux/config.guess) \
        --enable-install-program=hostname \
        --enable-no-install-program=kill,uptime \
    && make \
    && make DESTDIR=$LFS_BASE install \
    && mv -v $LFS_BASE/usr/bin/chroot $LFS_BASE/usr/sbin \
    && mkdir -pv $LFS_BASE/usr/share/man/man8 \
    && mv -v $LFS_BASE/usr/share/man/man1/chroot.1 $LFS_BASE/usr/share/man/man8/chroot.8 \
    && sed -i 's/"1"/"8"/' $LFS_BASE/usr/share/man/man8/chroot.8 \
    && popd \
    && rm -rf /tmp/coreutils

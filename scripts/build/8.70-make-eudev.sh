#!/bin/bash
set -e
echo "Building Eudev.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 83 MB"

# 8.70. Eudev
# The Eudev package contains programs for dynamic creation of device nodes.
tar -xf /sources/eudev-*.tar.gz -C /tmp/ \
    && mv /tmp/eudev-* /tmp/eudev \
    && pushd /tmp/eudev \
    && ./configure \
        --prefix=/usr \
        --bindir=/usr/sbin \
        --sysconfdir=/etc \
        --enable-manpages \
        --disable-static \
    && make \
    && mkdir -pv /usr/lib/udev/rules.d \
    && mkdir -pv /etc/udev/rules.d \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && tar -xvf /sources/udev-lfs-*.tar.xz \
    && make -f $(ls udev-lfs-*/Makefile.lfs) install \
    && udevadm hwdb --update \
    && popd \
    && rm -rf /tmp/eudev


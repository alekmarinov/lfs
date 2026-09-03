#!/bin/bash
# PACKAGE:  libnl
# SOURCE:   libnl-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libnl.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 15 MB"

# 9. libnl
# libnl is the netlink library the wireless tools talk to the kernel through.
# Both iw and wpa_supplicant use its nl80211 support, so neither builds without
# it - wpa_supplicant with CONFIG_DRIVER_NL80211 fails at link time.
# https://www.linuxfromscratch.org/blfs/view/11.2/basicnet/libnl.html
#
# BUILD_REQUIRES:
# RUNTIME_REQUIRES:

tar -xf /sources/libnl-*.tar.gz -C /tmp/ \
    && mv /tmp/libnl-* /tmp/libnl \
    && pushd /tmp/libnl \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/libnl

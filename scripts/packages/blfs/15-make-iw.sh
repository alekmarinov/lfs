#!/bin/bash
set -e
echo "Building BLFS-iw.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 4 MB"

# 9. iw
# iw configures the wireless interfaces through the nl80211 netlink interface:
# it scans for networks, reads the regulatory domain and reports the link state.
# It does not do the authentication of a protected network, that is
# wpa_supplicant.
# https://www.linuxfromscratch.org/blfs/view/11.2/basicnet/iw.html
#
# BUILD_REQUIRES: 17-make-libnl
# RUNTIME_REQUIRES:

tar -xf /sources/iw-*.tar.xz -C /tmp/ \
    && mv /tmp/iw-* /tmp/iw \
    && pushd /tmp/iw \
    && sed -i "/INSTALL.*gz/s/^/#/" Makefile \
    && make \
    && make SBINDIR=/usr/sbin install \
    && popd \
    && rm -rf /tmp/iw

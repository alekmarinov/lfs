#!/bin/bash
# PACKAGE:  wireless-regdb
# SOURCE:   wireless-regdb-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-wireless-regdb.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 1 MB"

# 9. wireless-regdb
# The wireless regulatory database tells the kernel which channels and transmit
# powers are legal in each country. Without it cfg80211 refuses to enable the
# regulated part of the spectrum, which on most cards is everything above
# channel 11, and the boot logs 'failed to load regulatory.db'.
#
# NOTE the kernel is built with CONFIG_CFG80211_REQUIRE_SIGNED_REGDB=y, so the
# signature file regulatory.db.p7s has to be installed next to the database and
# both have to be the ones shipped upstream. A regenerated database is rejected.
# https://www.linuxfromscratch.org/blfs/view/11.2/basicnet/wireless_tools.html
#
# BUILD_REQUIRES:
# RUNTIME_REQUIRES:

tar -xf /sources/wireless-regdb-*.tar.xz -C /tmp/ \
    && mv /tmp/wireless-regdb-* /tmp/wireless-regdb \
    && pushd /tmp/wireless-regdb \
    && install -v -d -m755 /lib/firmware \
    && install -v -m644 regulatory.db regulatory.db.p7s /lib/firmware/ \
    && install -v -d -m755 /usr/share/man/man5 \
    && install -v -m644 man/regulatory.db.5 /usr/share/man/man5/ 2>/dev/null || true \
    && popd \
    && rm -rf /tmp/wireless-regdb

#!/bin/bash
set -e
echo "Building BLFS-dhcpcd.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 11 MB"

# 14. dhcpcd
# dhcpcd is a DHCP client, it obtains the address and the routes of an interface
# from a DHCP server instead of them being configured statically.
# https://www.linuxfromscratch.org/blfs/view/11.2/basicnet/dhcpcd.html

# the privilege separation environment dhcpcd drops into
install -v -m700 -d /var/lib/dhcpcd
groupadd -g 52 dhcpcd 2>/dev/null || true
useradd -c 'dhcpcd PrivSep' -d /var/lib/dhcpcd -g dhcpcd -s /bin/false -u 52 dhcpcd 2>/dev/null || true
chown -v dhcpcd:dhcpcd /var/lib/dhcpcd

tar -xf /sources/dhcpcd-*.tar.gz -C /tmp/ \
    && mv /tmp/dhcpcd-* /tmp/dhcpcd \
    && pushd /tmp/dhcpcd \
    && sed '/Deny everything else/i SECCOMP_ALLOW(__NR_getrandom),' -i src/privsep-linux.c \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --libexecdir=/usr/lib/dhcpcd \
        --dbdir=/var/lib/dhcpcd \
        --runstatedir=/run \
        --privsepuser=dhcpcd \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/dhcpcd

# the dhcpcd network service comes from the BLFS bootscripts unpacked in /tmp
pushd /tmp/blfs-bootscripts \
    && make install-service-dhcpcd \
    && popd

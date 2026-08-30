#!/bin/bash
set -e
echo "Building BLFS-dhcpcd.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 11 MB"

# 14. dhcpcd
# dhcpcd is a DHCP client, it obtains the address and the routes of an interface
# from a DHCP server instead of them being configured statically.
# https://www.linuxfromscratch.org/blfs/view/11.2/basicnet/dhcpcd.html
#
# NOTE dhcpcd.conf is installed by hand. Version 9 installed it as part of
# 'make install' and 10 no longer does, so without this dhcpcd falls back to
# built-in defaults and prints 'read_config: /etc/dhcpcd.conf: No such file or
# directory' on every boot. The file is the one shipped in this version's own
# source rather than a copy kept here, so it stays matched to the program.
#
# NOTE dhcpcd 10, not the 9.4.1 BLFS 11.2 pins. dhcpcd sandboxes its
# privilege-separated helpers with a seccomp allow-list of the syscalls it
# expects to make, and anything outside that list kills the process. 9.4.1's
# list has 34 entries and predates the ones glibc 2.42 reaches for, so every
# helper died as soon as it was spoken to and dhcpcd hung with
# 'ps_sendcmdmsg: Connection refused' having sent no DISCOVER at all. It was
# already carrying a local patch adding __NR_getrandom for the same reason;
# 10.2.4 lists 59 syscalls including that one, so the patch is gone.

# the privilege separation environment dhcpcd drops into
install -v -m700 -d /var/lib/dhcpcd
groupadd -g 52 dhcpcd 2>/dev/null || true
useradd -c 'dhcpcd PrivSep' -d /var/lib/dhcpcd -g dhcpcd -s /bin/false -u 52 dhcpcd 2>/dev/null || true
chown -v dhcpcd:dhcpcd /var/lib/dhcpcd

tar -xf /sources/dhcpcd-*.tar.* -C /tmp/ \
    && mv /tmp/dhcpcd-* /tmp/dhcpcd \
    && pushd /tmp/dhcpcd \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --libexecdir=/usr/lib/dhcpcd \
        --dbdir=/var/lib/dhcpcd \
        --runstatedir=/run \
        --privsepuser=dhcpcd \
    && make \
    && make install \
    && install -v -m644 src/dhcpcd.conf /etc/dhcpcd.conf \
    && popd \
    && rm -rf /tmp/dhcpcd

# the dhcpcd network service comes from the BLFS bootscripts unpacked in /tmp
# Unpack the bootscripts here unless an earlier package left them behind:
# every package builds in its own overlay, so /tmp is not a reliable way to
# hand a tree from one package to the next.
[ -d /tmp/blfs-bootscripts ] \
    || { tar -xf /sources/blfs-bootscripts-*.tar.xz -C /tmp/ \
         && mv /tmp/blfs-bootscripts-* /tmp/blfs-bootscripts; }

pushd /tmp/blfs-bootscripts \
    && make install-service-dhcpcd \
    && popd

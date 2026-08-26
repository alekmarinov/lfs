#!/bin/bash
set -e
echo "Managing Devices.."

# 9.4. Managing Devices
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter09/symlinks.html

# 9.4.2. Dealing with duplicate devices - network interface naming
#
# The persistent network rules must NOT be generated here: this script runs on
# the build machine, so /usr/lib/udev/init-net-rules.sh would record the MAC
# addresses of the *builder's* network cards. On any other machine no rule
# matches, udev falls back to the predictable names (enp0s2, ...) and the
# ifconfig.eth0 configuration written by 9.5-configure-network.sh is never
# applied - the network fails to come up at boot.
#
# Instead the predictable naming is disabled, so the kernel names are kept and
# the first ethernet interface is eth0 on every machine this image boots on.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter09/udev.html
install -v -dm755 /etc/udev/rules.d
ln -sfv /dev/null /etc/udev/rules.d/80-net-name-slot.rules

# drop any rules left over from a previous build which bound the interface
# names to the build machine's network cards
rm -fv /etc/udev/rules.d/70-persistent-net.rules

echo "Predictable network interface naming disabled, interfaces keep the kernel names (eth0, ...)"

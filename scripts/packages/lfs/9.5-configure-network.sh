#!/bin/bash
# PACKAGE:  network
# VERSION:  12.4
# RELEASE:  1
# CLASS:    core
set -e
echo "Setup general network configuration.."

# 9.5. General Network Configuration
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter09/network.html

# 9.5.1. Creating Network Interface Configuration Files
cd /etc/sysconfig/
# The address is obtained from a DHCP server rather than configured statically,
# so that the image comes up on any network it is booted on. QEMU answers with
# 10.0.2.15 from its user mode network, a router answers with a lease.
cat > ifconfig.eth0 <<"EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=dhcpcd
DHCP_START="-b -q"
DHCP_STOP="-k"
EOF

# 9.5.2. Creating the /etc/resolv.conf File
cat > /etc/resolv.conf <<"EOF"
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# 9.5.3. Configuring the system hostname
echo "lfs" > /etc/hostname

# 9.5.4. Customizing the /etc/hosts File
cat > /etc/hosts <<"EOF"
127.0.0.1 localhost
# 127.0.1.1 <FQDN> <HOSTNAME>
# <192.168.1.1> <FQDN> <HOSTNAME> [alias1] [alias2 ...]
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

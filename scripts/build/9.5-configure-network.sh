#!/bin/bash
set -e
echo "Setup general network configuration.."

# 9.5. General Network Configuration
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter09/network.html

# 9.5.1. Creating Network Interface Configuration Files
cd /etc/sysconfig/
cat > ifconfig.eth0 <<"EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=10.0.2.15
GATEWAY=10.0.2.2
PREFIX=24
BROADCAST=10.0.2.255
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

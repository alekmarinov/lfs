#!/bin/bash
set -e
echo "Managing Devices.."

# 9.4. Managing Devices
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter09/symlinks.html

# patch script with docker vendor MAC prefix
sed -i "/declare -A VENDORS$/aVENDORS['02:42:ac:']=\"docker\"" /usr/lib/udev/init-net-rules.sh

# generate udev rules for networking
bash /usr/lib/udev/init-net-rules.sh
cat /etc/udev/rules.d/70-persistent-net.rules

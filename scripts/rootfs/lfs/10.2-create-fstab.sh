#!/bin/bash
set -e
echo "Creating fstab.."

# 10.2. Creating the /etc/fstab File
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter10/fstab.html

cat > /etc/fstab <<"EOF"
# file system   mount-point   type      options               dump  fsck
#                                                                   order

/dev/ram        /             auto      defaults              1     1
proc            /proc         proc      nosuid,noexec,nodev   0     0
sysfs           /sys          sysfs     nosuid,noexec,nodev   0     0
devpts          /dev/pts      devpts    gid=5,mode=620        0     0
tmpfs           /run          tmpfs     defaults              0     0
devtmpfs        /dev          devtmpfs  mode=0755,nosuid      0     0

EOF

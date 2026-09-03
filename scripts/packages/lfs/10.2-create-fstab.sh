#!/bin/bash
# PACKAGE:  fstab
# VERSION:  12.4
# RELEASE:  1
# CLASS:    core
set -e
echo "Creating fstab.."

# 10.2. Creating the /etc/fstab File
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter10/fstab.html
#
# NOTE the /dev/shm and /sys/fs/cgroup lines are what LFS 12.x added. The
# mountvirtfs bootscript mounts both by mount point alone, so without an entry
# here it cannot find them and the very first bootscript fails.

cat > /etc/fstab <<"EOF"
# file system   mount-point   type      options               dump  fsck
#                                                                   order

__ROOT_DEV__    /             auto      defaults              1     1
proc            /proc         proc      nosuid,noexec,nodev   0     0
sysfs           /sys          sysfs     nosuid,noexec,nodev   0     0
devpts          /dev/pts      devpts    gid=5,mode=620        0     0
tmpfs           /run          tmpfs     defaults              0     0
devtmpfs        /dev          devtmpfs  mode=0755,nosuid      0     0
tmpfs           /dev/shm      tmpfs     nosuid,nodev          0     0
cgroup2         /sys/fs/cgroup cgroup2  nosuid,noexec,nodev   0     0

EOF

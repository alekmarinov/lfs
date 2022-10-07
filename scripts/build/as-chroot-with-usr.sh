#!/bin/bash
set -e
echo "Continue with chroot environment.."

# configure system
sh /tools/9.2-make-lfs-bootscripts.sh
sh /tools/9.4-managing-devices.sh
sh /tools/9.5-configure-network.sh
sh /tools/9.6-configure-systemv.sh
sh /tools/9.7-configure-bash.sh
sh /tools/9.8-configure-inputrc.sh
sh /tools/9.9-configure-shells.sh
sh /tools/10.2-create-fstab.sh
sh /tools/10.3-make-linux-kernel.sh
sh /tools/10.4-setup-grub.sh
sh /tools/11.1-the-end.sh

# make system bootable
sh /tools/7.2-make-lfs-bootscripts.sh
sh /tools/7.4-manage-devices.sh
sh /tools/7.5-configure-network.sh
sh /tools/7.6-configure-systemv.sh
sh /tools/7.x-configure-bash.sh
sh /tools/8.2-create-fstab.sh
sh /tools/8.3-make-linux-kernel.sh
sh /tools/8.4-setup-grub.sh

# end
sh /tools/9.1-the-end.sh

exit

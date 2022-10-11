#!/bin/bash
set -e
echo "Start building bootable image.."

pushd /tmp
mkdir isolinux

sh $LFS/scripts/image/1.configure-syslinux.sh
sh $LFS/scripts/image/2.create-ramdisk.sh
sh $LFS/scripts/image/3.build-iso.sh

rm -rf isolinux
popd

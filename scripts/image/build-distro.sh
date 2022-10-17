#!/bin/bash
set -e
pkglist=$1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

[ -d packages ] || ( echo "Directory 'packages' is missing!" && exit 1)

if [[ "$pkglist" == "" ]]; then
    echo "Missing expected argument pkglist"
    exit 1
fi

ROOTFS_DIR="rootfs"

[ -d "$ROOTFS_DIR" ] && ( echo "Directory '$ROOTFS_DIR' exists, aborting" && exit 1 )
mkdir -v "$ROOTFS_DIR"
while read -r package; do
    tar xvf "packages/$package" -C "$ROOTFS_DIR"
done < "$SCRIPT_DIR/$pkglist.pkglist"

# Check size in KB occuppied by the files in rootfs
IMAGE_SIZE=$(du -d0 "$ROOTFS_DIR"/ | awk '{ print $1 }')

# Double the size to have available room
IMAGE_SIZE=$(echo $IMAGE_SIZE \* 2 | bc)

# Make a partition in a file
dd if=/dev/zero of=rootfs.img bs=1k count=$IMAGE_SIZE status=progress

# Attach the image file to available loop device
LOOP=$(losetup -f)

losetup $LOOP rootfs.img
mkfs.ext4 $LOOP -d "$ROOTFS_DIR"
sync
losetup -d $LOOP

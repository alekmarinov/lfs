#!/bin/bash
# Builds bootable image with uefi in the current directory
# The script requires root privileges and expects the folowing environment variables:
set -e

# The linux rootfs directory is expected in 'LFS' variable
if [[ "$LFS" == "" ]]; then
    echo "Missing expected 'LFS' environment variable"
    exit 1
fi

# The name of the produced image file
IMAGE_FILE=${IMAGE_FILE:-lfs.img}

# the image size in MB, default 10000 (10G)
IMAGE_SIZE=${IMAGE_SIZE:-10000}

# the root device to boot from (default /dev/sdb2)
ROOT_DEV=${ROOT_DEV:-/dev/sdb2}

# Basic check of the $LFS structure
for sub in boot dev etc lib proc run sbin sys usr var; do
    [ -d "$LFS/$sub" ] || echo "Missing '$LFS/$sub' directory!" && exit 1
done

for file in usr/sbin/grub-install usr/sbin/chroot; do
    [ -f "$LFS/$file" ] || echo "Missing '$LFS/$file' file!" && exit 1
done

if [[ $(grep __ROOT_DEV__ "$LFS/etc/fstab") == "" ]]; then
    echo "The script can't find the string __ROOT_DEV__ inside '$LFS/etc/fstab' file 
to substitute it with '$ROOT_DEV' where the root (/) will be mounted."
    exit 1
fi

# Attach the image file to available loop device
LOOP=$(losetup -f)

if [[ "$LOOP" == "" ]]; then
    echo "Can't find available loop device."
    echo "Here is the losetup output:"
    losetup -l
    exit 1
fi

echo "Building '$IMAGE_FILE' started..."

# Produces the image file full with zeros
dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=$IMAGE_SIZE

# Associates the loop device with the image file
losetup "$LOOP" "$IMAGE_FILE"

# Create partitions for EFI and root file system
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $LOOP
n # create 10M vfat partition for EFI
p
1

+10M
t
ef
n # create ext4 partition with the reamining space
p
2


w # save changes and exit
EOF

# Recreate $LOOP as partitioned loop device with the option -P
losetup -d "$LOOP"
losetup -P "$LOOP" "$IMAGE_FILE"

# Format EFI vfat partition
mkfs.vfat "${LOOP}p1"

# Format rootfs ext4 partition
mkfs.ext4 "${LOOP}p2"

# Mount rootfs partition to empty rootfs directory
ROOTFS_DIR="$PWD/rootfs"
mkdir -v "$ROOTFS_DIR"
mount "${LOOP}p2" "$ROOTFS_DIR"

# Copy lfs files to the mounted rootfs directory
pushd "$LFS"
cp -dpR $(ls -A | grep -Ev "sources|tools|scripts") "$ROOTFS_DIR"
popd "$LFS"

# Create and mount efi directory
mkdir -v "$ROOTFS_DIR/boot/efi"
mount "${LOOP}p1" "$ROOTFS_DIR/boot/efi"

# Mount virtual kernel file system
mount -v --bind /dev $ROOTFS_DIR/dev
mount -v --bind /dev/pts $ROOTFS_DIR/dev/pts
mount -vt proc proc $ROOTFS_DIR/proc
mount -vt sysfs sysfs $ROOTFS_DIR/sys
mount -vt tmpfs tmpfs $ROOTFS_DIR/run

# grub-install in chrooted rootfs
chroot "$ROOTFS_DIR" grub-install --target=x86_64-efi --removable

# Unount virtual kernel file system
sudo umount -v $ROOTFS_DIR/run
sudo umount -v $ROOTFS_DIR/sys
sudo umount -v $ROOTFS_DIR/proc
sudo umount -v $ROOTFS_DIR/dev/pts
sudo umount -v $ROOTFS_DIR/dev

# Configure grub
KERNEL_NAME=$(basename $(ls $ROOTFS_DIR/boot/vmlinuz* | head -1))
cat > $ROOTFS_DIR/boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,2)

if loadfont /boot/grub/fonts/unicode.pf2; then
    set gfxmode=auto
    insmod all_video
    terminal_output gfxterm
fi

menuentry "LFS Linux, $KERNEL_NAME" {
    linux   /boot/vmlinuz-5.19.2-lfs-11.2 root=$ROOT_DEV ro
}
EOF

# Configure fstab
sed -i "s/__ROOT_DEV__/${ROOT_DEV//\//\\\/}/" $ROOTFS_DIR/etc/fstab

# unmount rootfs and efi
umount -v "$ROOTFS_DIR/boot/efi"
umount -v "$ROOTFS_DIR"

# detach the loop device
losetup -d "$LOOP"

echo "
Building $IMAGE_FILE from $LFS finsihed.
Plug USB memory stick and try
\$dd if=$IMAGE_FILE of=/dev/sdb status=progress
Then boot from a PC with UEFI support.
Note: Make sure the USB stick have at least ${IMAGE_SIZE}M available space
"

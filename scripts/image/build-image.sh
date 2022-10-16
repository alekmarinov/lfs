#!/bin/bash
# Builds bootable image with uefi
set -e

# The linux rootfs directory is expected in 'LFS' variable
if [[ "$LFS" == "" ]]; then
    echo "Missing expected 'LFS' environment variable"
    exit 1
fi
LFS=$(readlink -f "$LFS")
echo "'LFS' is set to $LFS"

# The name of the produced image file
IMAGE_FILE=${IMAGE_FILE:-lfs.img}

# the image size in MB, default 10000 (10G)
IMAGE_SIZE=${IMAGE_SIZE:-10240}

# the root device to boot from (default /dev/sdb2)
ROOT_DEV=${ROOT_DEV:-/dev/sdb2}

# the directory to mount the rootfs partition
ROOTFS_DIR="$(dirname $(readlink -f $IMAGE_FILE))/rootfs"

echo "Using IMAGE_FILE=$IMAGE_FILE, IMAGE_SIZE=$IMAGE_SIZE, ROOT_DEV=$ROOT_DEV"

# Basic check of the rootfs directories
for sub in boot dev etc lib proc run sbin sys usr var; do
    [ -d "$LFS/$sub" ] || (echo "Missing '$LFS/$sub' directory!" && exit 1)
done
echo "The expected directories in '$LFS' are present"

for file in usr/sbin/grub-install usr/sbin/chroot; do
    [ -f "$LFS/$file" ] || (echo "Missing '$LFS/$file' file!" && exit 1)
done
echo "The expected files in '$LFS' are present"

if [[ $(grep __ROOT_DEV__ "$LFS/etc/fstab") == "" ]]; then
    echo "The script can't find the string __ROOT_DEV__ inside '$LFS/etc/fstab' file 
to substitute it with '$ROOT_DEV' where the root (/) will be mounted."
    exit 1
fi
echo "__ROOT_DEV__ in '$LFS/etc/fstab' is present"

# Attach the image file to available loop device
LOOP=$(losetup -f)

if [[ "$LOOP" == "" ]]; then
    echo "Can't find available loop device."
    echo "Here is the losetup output:"
    losetup -l
    exit 1
fi
echo "Found available loop device at '$LOOP'"

handle_error() {
    echo "Script break at line $1"
    set +e
    sync
    umount -v $ROOTFS_DIR/run
    umount -v $ROOTFS_DIR/sys
    umount -v $ROOTFS_DIR/proc
    umount -v $ROOTFS_DIR/dev/pts
    umount -v $ROOTFS_DIR/dev
    umount -v "$ROOTFS_DIR/boot/efi"
    umount -v "$ROOTFS_DIR"
    losetup -d "$LOOP"
    exit 1
}

trap 'handle_error $LINENO' ERR

echo "Creating '$IMAGE_FILE' file..."
# Produces the image file full with zeros
dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=$IMAGE_SIZE status=progress
sync

echo "Associating '$LOOP' with '$IMAGE_FILE'..."
# Associates the loop device with the image file
losetup "$LOOP" "$IMAGE_FILE"

echo "Creating EFI and rootfs partitions..."
# Create partitions for EFI and root file system
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $LOOP || true
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
sync

echo "Reassociating '$LOOP' device with -P option ..."
# Reassociate $LOOP as partitioned loop device with the option -P
losetup -d "$LOOP"
losetup -P "$LOOP" "$IMAGE_FILE"

echo "Formatting EFI vfat partition at '${LOOP}p1'..."
# Format EFI vfat partition
mkfs.vfat "${LOOP}p1"

echo "Formatting rootfs ext4 partition at '${LOOP}p2'..."
# Format rootfs ext4 partition
mkfs.ext4 "${LOOP}p2"

# Mount rootfs partition to empty rootfs directory
mkdir -v "$ROOTFS_DIR"
echo "Mounting rootfs directory at '${LOOP}p2' -> '$ROOTFS_DIR'..."
mount "${LOOP}p2" "$ROOTFS_DIR"

echo "Copying rootfs files '$LFS' -> '$ROOTFS_DIR'..."
# Copy lfs files to the mounted rootfs directory
pushd "$LFS"
cp -dpR $(ls -A | grep -Ev "sources|tools|scripts") "$ROOTFS_DIR"
popd
sync

# grub-install expects the efi partition mounted to /boot/efi
mkdir -v "$ROOTFS_DIR/boot/efi"
echo "Mounting efi directory '${LOOP}p1' -> '$ROOTFS_DIR/boot/efi'..."
mount "${LOOP}p1" "$ROOTFS_DIR/boot/efi"

echo "Mounting vkfs in rootfs directory $ROOTFS_DIR..."
# Mount virtual kernel file system
mount -v --bind /dev $ROOTFS_DIR/dev
mount -v --bind /dev/pts $ROOTFS_DIR/dev/pts
mount -vt proc proc $ROOTFS_DIR/proc
mount -vt sysfs sysfs $ROOTFS_DIR/sys
mount -vt tmpfs tmpfs $ROOTFS_DIR/run

echo "grub-install with chroot in '$ROOTFS_DIR'..."
# grub-install in chrooted rootfs
chroot "$ROOTFS_DIR" grub-install --target=x86_64-efi --removable
sync

# Unount virtual kernel file system
echo "Unmounting vkfs from rootfs directory $ROOTFS_DIR..."
umount -v $ROOTFS_DIR/run
umount -v $ROOTFS_DIR/sys
umount -v $ROOTFS_DIR/proc
umount -v $ROOTFS_DIR/dev/pts
umount -v $ROOTFS_DIR/dev

echo "Configuring grub..."
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
    linux   /boot/vmlinuz-5.19.2-lfs-11.2 rootwait root=$ROOT_DEV ro
}
EOF

echo "Configuring $ROOTFS_DIR/etc/fstab with root device '$ROOT_DEV'..."
# Configure fstab
sed -i "s/__ROOT_DEV__/${ROOT_DEV//\//\\\/}/" $ROOTFS_DIR/etc/fstab

# unmount rootfs and efi
echo "Umounting '$ROOTFS_DIR/boot/efi'..."
umount -v "$ROOTFS_DIR/boot/efi"
echo "Umounting '$ROOTFS_DIR'..."
umount -v "$ROOTFS_DIR"
sync

echo "Detaching loop device '$LOOP'..."
# detach the loop device
losetup -d "$LOOP"

echo "
Building $IMAGE_FILE from $LFS finsihed.
Plug USB memory stick with at least $(echo $IMAGE_SIZE / 1024 | bc)G available space and try
\$ sudo dd if=$IMAGE_FILE of=/dev/sdb status=progress
Then boot from a PC and enjoy your LFS Linux!
"

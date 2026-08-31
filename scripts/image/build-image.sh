#!/bin/bash
# Turns the assembled rootfs into a bootable uefi image
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )

# Same argument as build-distro.sh. 'make image' used to take none, because
# there was one shared rootfs/ and nothing to choose between - which is also
# why EXPECT_DISTRO had to exist. With one output directory per distro the
# path comes from the same place the assembly did, and there is nothing left
# to disagree about.
OUT=$("$SCRIPT_DIR/../resolve-distro.sh" -o "$1")
ROOTFS_DIR="$OUT/rootfs"

# The name of the produced image file
IMAGE_FILE=${IMAGE_FILE:-$OUT/image.img}

# IMAGE_SIZE is resolved further down, from the distro's own distro.conf. It
# used to come from .env, which meant one number for every distro whatever it
# held - and .env is exported wholesale by the Makefile, so a per-distro value
# could never have won against it. How big its image needs to be is a property
# of the distro, so that is where it is declared now.

# the directory the image partitions are mounted on while it is being built
MNT_DIR="$(dirname $(readlink -f $IMAGE_FILE))/mnt"

[ -d "$ROOTFS_DIR" ] || { echo "Directory '$ROOTFS_DIR' is missing, run 'make distro DISTRO=...' first"; exit 1; }

# 'make image' images whatever rootfs/ holds - it has no DISTRO of its own. So
# 'make image DISTRO=full' with a minimal-desktop in rootfs/ would quietly
# produce a minimal-desktop image under a name which says otherwise. If DISTRO
# was given on the command line, it has to agree with what is actually there.
DISTRO_IN_ROOTFS=$(sed -n 's/^DISTRO=//p' "$ROOTFS_DIR/etc/lfs-distro" 2>/dev/null)
ID_IN_ROOTFS=$(sed -n 's/^ID=//p' "$ROOTFS_DIR/etc/lfs-distro" 2>/dev/null)
# DISTRO= may have been a bare name or a path, so the rootfs records both what
# was asked for and the ID it resolved to. Either one agreeing is agreement.
if [[ "$EXPECT_DISTRO" != "" && "$DISTRO_IN_ROOTFS" != "" \
      && "$EXPECT_DISTRO" != "$DISTRO_IN_ROOTFS" \
      && "$EXPECT_DISTRO" != "$ID_IN_ROOTFS" ]]; then
    echo "'$ROOTFS_DIR' holds the distro '$DISTRO_IN_ROOTFS', not '$EXPECT_DISTRO'.
Assemble the one you want first:

    make distro DISTRO=$EXPECT_DISTRO FORCE=1
    sudo make image

or drop DISTRO= to image the '$DISTRO_IN_ROOTFS' which is already assembled."
    exit 1
fi

# Rewriting the image while a machine is booted from it corrupts both: the
# running system reads a file system which changed underneath it, and writes
# its stale buffers back into the new one. QEMU takes only an advisory lock,
# which dd does not honour, so the check has to happen here.
holders=$(pgrep -af qemu-system-x86_64 2>/dev/null \
    | grep -E "^[0-9]+ (sudo +)?([^ ]*/)?qemu-system-x86_64 " \
    | grep -F -- "$(basename "$IMAGE_FILE")" \
    | cut -d' ' -f1 | tr '\n' ',' | sed 's/,$//')
if [ -n "$holders" ]; then
    echo "'$IMAGE_FILE' is booted right now by:"
    ps -o pid,etime,command -p "$holders" --no-headers 2>/dev/null | cut -c1-100 | sed 's/^/    /'
    echo "
Rebuilding it now would corrupt both the running system and the new image.
Shut the machine down first - press its power button, or run 'poweroff' in it,
or stop it with

    sudo kill ${holders//,/ }
"
    exit 1
fi

for file in usr/sbin/grub-install usr/sbin/chroot; do
    [ -f "$ROOTFS_DIR/$file" ] || { echo "Missing '$ROOTFS_DIR/$file', the distro can't be made bootable"; exit 1; }
done

KERNEL_NAME=$(basename $(sudo ls "$ROOTFS_DIR"/boot/vmlinuz* 2>/dev/null | head -1) 2>/dev/null)
[ "$KERNEL_NAME" != "" ] || { echo "No kernel in '$ROOTFS_DIR/boot', the distro can't be made bootable"; exit 1; }

if [[ $(sudo grep __ROOT_DEV__ "$ROOTFS_DIR/etc/fstab") == "" ]]; then
    echo "The script can't find the string __ROOT_DEV__ inside '$ROOTFS_DIR/etc/fstab' file
to substitute it with the partition the root (/) will be mounted from."
    exit 1
fi

# identity of the distro being made bootable
PRETTY_NAME=$(sed -n 's/^PRETTY_NAME="\(.*\)"/\1/p' "$ROOTFS_DIR/etc/os-release" 2>/dev/null)
PRETTY_NAME=${PRETTY_NAME:-Linux}

# How long the menu waits, what is on the kernel command line, and how big the
# image is are the distro's business, not this script's: an appliance wants to
# boot straight through in silence and a desktop wants a menu you can actually
# catch. All are read from the distro's own distro.conf, with the old defaults
# when it says nothing. They are read with sed rather than sourced - that file is
# configuration, and sourcing it would let it set anything in here.
DISTRO_CONF="$ROOTFS_DIR/etc/lfs-distro.d/distro.conf"
conf_value() {
    [ -f "$DISTRO_CONF" ] || return 0
    sed -n "s/^$1=\"\\(.*\\)\"$/\\1/p; s/^$1=\\([^\"]*\\)$/\\1/p" "$DISTRO_CONF" | tail -1
}
GRUB_TIMEOUT=${GRUB_TIMEOUT:-$(conf_value GRUB_TIMEOUT)}
GRUB_TIMEOUT=${GRUB_TIMEOUT:-5}
KERNEL_CMDLINE=${KERNEL_CMDLINE:-$(conf_value KERNEL_CMDLINE)}
KERNEL_CMDLINE=${KERNEL_CMDLINE:-net.ifnames=0}
IMAGE_SIZE=${IMAGE_SIZE:-$(conf_value IMAGE_SIZE)}
IMAGE_SIZE=${IMAGE_SIZE:-7168}
case "$IMAGE_SIZE" in
    ""|*[!0-9]*) echo "IMAGE_SIZE '$IMAGE_SIZE' is not a number of megabytes"; exit 1 ;;
esac

echo "Using IMAGE_FILE=$IMAGE_FILE, IMAGE_SIZE=$IMAGE_SIZE, building '$PRETTY_NAME'"
echo "Kernel command line: $KERNEL_CMDLINE"
echo "Menu timeout: ${GRUB_TIMEOUT}s"

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
    umount -v $MNT_DIR/run
    umount -v $MNT_DIR/sys
    umount -v $MNT_DIR/proc
    umount -v $MNT_DIR/dev/pts
    umount -v $MNT_DIR/dev
    umount -v "$MNT_DIR/boot/efi"
    umount -v "$MNT_DIR"
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

# The EFI partition is 100M rather than 10M: a kernel alone is over 10M, and
# an ESP that can also hold one is what makes an EFI stub boot possible.
echo "Creating EFI and rootfs partitions..."
# Create partitions for EFI and root file system
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $LOOP || true
n # create 100M vfat partition for EFI
p
1

+100M
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

# The root partition is addressed by its PARTUUID instead of a device name, so
# that the same image boots wherever it is plugged in - as the first disk under
# QEMU or as a USB stick on a PC which already has disks.
ROOT_DEV="PARTUUID=$(blkid -s PARTUUID -o value ${LOOP}p2)"
echo "The root partition is identified by '$ROOT_DEV'"

# Mount rootfs partition to empty mnt directory
rm -rf "$MNT_DIR"
mkdir -v "$MNT_DIR"
echo "Mounting rootfs directory at '${LOOP}p2' -> '$MNT_DIR'..."
mount "${LOOP}p2" "$MNT_DIR"

echo "Copying '$ROOTFS_DIR' -> '$MNT_DIR'..."
cp -a "$ROOTFS_DIR/." "$MNT_DIR/"
sync

# Basic check of the rootfs directories
for sub in boot dev etc lib proc run sbin sys usr var; do
    [ -d "$MNT_DIR/$sub" ] || (echo "Missing '$MNT_DIR/$sub' directory!" && exit 1)
done
echo "The expected directories in '$MNT_DIR' are present"

# grub-install expects the efi partition mounted to /boot/efi
mkdir -pv "$MNT_DIR/boot/efi"
echo "Mounting efi directory '${LOOP}p1' -> '$MNT_DIR/boot/efi'..."
mount "${LOOP}p1" "$MNT_DIR/boot/efi"

echo "Mounting vkfs in rootfs directory $MNT_DIR..."
# Mount virtual kernel file system
mount -v --bind /dev $MNT_DIR/dev
mount -v --bind /dev/pts $MNT_DIR/dev/pts
mount -vt proc proc $MNT_DIR/proc
mount -vt sysfs sysfs $MNT_DIR/sys
mount -vt tmpfs tmpfs $MNT_DIR/run

echo "grub-install with chroot in '$MNT_DIR'..."
# grub-install in chrooted rootfs
chroot "$MNT_DIR" env -i PATH=/usr/bin:/usr/sbin grub-install --target=x86_64-efi --removable
sync

# Unount virtual kernel file system
echo "Unmounting vkfs from rootfs directory $MNT_DIR..."
umount -v $MNT_DIR/run
umount -v $MNT_DIR/sys
umount -v $MNT_DIR/proc
umount -v $MNT_DIR/dev/pts
umount -v $MNT_DIR/dev

echo "Configuring grub..."
# The cpu microcode is handed to the kernel as an early initrd, when the distro
# packed one. The processor applies it before the root file system is mounted.
if [ -f "$MNT_DIR/boot/microcode.img" ]; then
    MICROCODE_LINE="    initrd  /boot/microcode.img
"
    echo "Loading the cpu microcode from /boot/microcode.img"
else
    MICROCODE_LINE=""
fi

# This script generates the two entries it can derive from the kernel command
# line: the default, and the same thing with the console made verbose. Every
# other entry a distro wants - a rescue mode, an alternative for a machine
# whose hardware needs different flags - is the distro's own knowledge, and it
# declares them in a 'boot-entries' file in its own directory:
#
#     rescue: console only|net.ifnames=0 someflag
#     with nouveau|net.ifnames=0 quiet loglevel=0
#
# one per line, title before the '|' and the kernel command line after it,
# blank lines and '#' comments ignored. Read rather than sourced, like
# distro.conf, so that a distro file cannot set variables in this script.
# A distro that declares nothing gets the two entries below and no others.
EXTRA_ENTRIES=""
BOOT_ENTRIES="$ROOTFS_DIR/etc/lfs-distro.d/boot-entries"
if [ -f "$BOOT_ENTRIES" ]; then
    while IFS='|' read -r entry_title entry_cmdline || [ -n "$entry_title" ]; do
        case "$entry_title" in ""|"#"*) continue ;; esac
        if [ -z "$entry_cmdline" ]; then
            echo "$BOOT_ENTRIES: entry '$entry_title' declares no kernel command line"
            exit 1
        fi
        EXTRA_ENTRIES="$EXTRA_ENTRIES
menuentry \"$PRETTY_NAME ($entry_title)\" {
    set gfxpayload=keep
    linux   /boot/$KERNEL_NAME rootwait root=$ROOT_DEV ro $entry_cmdline
$MICROCODE_LINE}
"
    done < "$BOOT_ENTRIES"
    echo "Boot entries from the distro:$(grep -vE '^[[:space:]]*(#|$)' "$BOOT_ENTRIES" \
        | sed 's/|.*//; s/^/ /' | tr '\n' ',' | sed 's/,$//')"
fi

# Configure grub
cat > $MNT_DIR/boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
# hidden shows no menu but still watches the keyboard for the timeout. Without
# it, 'timeout=0' boots at once and never reads a key, so a distro which sets
# zero to boot straight through has no way back to the menu - on EFI holding
# shift does not help either. One second of black screen buys a reachable
# rescue entry; press Esc during it.
set timeout_style=hidden
set timeout=$GRUB_TIMEOUT

insmod part_msdos
insmod ext2
search --set=root --fs-uuid $(blkid -s UUID -o value ${LOOP}p2)

if loadfont /boot/grub/fonts/unicode.pf2; then
    set gfxmode=auto
    insmod all_video
    terminal_output gfxterm
fi

# net.ifnames=0 keeps the kernel's eth0, eth1 names. udev otherwise derives a
# name from where the card sits on the bus - enp0s2 under qemu, something else
# on each real machine - and the interface configuration in /etc/sysconfig is
# written for eth0. One image is meant to boot on several machines, so the
# stable-across-machines name is the useful one here.
menuentry "$PRETTY_NAME" {
    # Hand the frame buffer grub is using straight to the kernel. Without this
    # grub restores the text mode before booting, and a machine which booted
    # over UEFI has no VGA text mode to go back to - the screen goes black at
    # exactly the moment the kernel starts.
    set gfxpayload=keep
    linux   /boot/$KERNEL_NAME rootwait root=$ROOT_DEV ro $KERNEL_CMDLINE
$MICROCODE_LINE}

# A machine which comes up with a lit but empty screen is almost always a
# console problem rather than a hang: the kernel is running and has nowhere to
# print. This entry writes straight to the framebuffer the firmware handed
# over, from the first line of the boot, and keeps doing so after the kernel
# switches to its own console. It is slow - every scrolled line is a copy over
# uncached memory - but it turns a black screen into a readable log.
$EXTRA_ENTRIES
menuentry "$PRETTY_NAME (verbose console)" {
    set gfxpayload=keep
    linux   /boot/$KERNEL_NAME rootwait root=$ROOT_DEV ro $KERNEL_CMDLINE earlycon=efifb keep_bootcon
$MICROCODE_LINE}

EOF

echo "Configuring $MNT_DIR/etc/fstab with root device '$ROOT_DEV'..."
# Configure fstab
sed -i "s|__ROOT_DEV__|$ROOT_DEV|" $MNT_DIR/etc/fstab

# unmount rootfs and efi
echo "Umounting '$MNT_DIR/boot/efi'..."
umount -v "$MNT_DIR/boot/efi"
echo "Umounting '$MNT_DIR'..."
umount -v "$MNT_DIR"
sync
rm -rf "$MNT_DIR"

echo "Detaching loop device '$LOOP'..."
# detach the loop device
losetup -d "$LOOP"

echo "
Building $IMAGE_FILE with '$PRETTY_NAME' finished.
Boot it with 'make qemu' or plug a USB memory stick with at least $(echo \($IMAGE_SIZE + 1023\) / 1024 | bc)G available space and try
\$ sudo dd if=$IMAGE_FILE of=/dev/sdb status=progress
Then boot from a PC and enjoy your LFS Linux!
"

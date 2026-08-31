#!/bin/bash
# Boots the produced image with QEMU
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Same argument as build-distro.sh and build-image.sh: one distro, one output
# directory, every script deriving it the same way.
OUT=$("$SCRIPT_DIR/../resolve-distro.sh" -o "$1")
shift
IMAGE_FILE=${IMAGE_FILE:-$OUT/image.img}

[ -f "$IMAGE_FILE" ] || { echo "'$IMAGE_FILE' is missing, run 'make image' first"; exit 1; }

# QEMU takes a write lock on the image, so a second machine booting the same
# image fails with a message which does not name the process holding it.
#
# NOTE the process name is matched on the whole command line: 'pkill -x
# qemu-system-x86_64' silently matches nothing, process names are cut at 15
# characters and that one is longer.
# The command line has to start with qemu itself, optionally through sudo: any
# other process which merely mentions the image - a shell running this very
# check among them - is not holding the image.
holders=$(pgrep -af qemu-system-x86_64 2>/dev/null \
    | grep -E "^[0-9]+ (sudo +)?([^ ]*/)?qemu-system-x86_64 " \
    | grep -F -- "$(basename "$IMAGE_FILE")" \
    | cut -d' ' -f1 | tr '\n' ',' | sed 's/,$//')
if [ -n "$holders" ]; then
    echo "'$IMAGE_FILE' is already booted by:"
    ps -o pid,etime,command -p "$holders" --no-headers 2>/dev/null | cut -c1-100 | sed 's/^/    /'
    echo "
Only one machine at a time can boot an image, QEMU keeps it write locked.
Stop the running one with

    sudo kill ${holders//,/ }
"
    exit 1
fi

# The image carries a uefi boot loader only, so QEMU needs the OVMF firmware.
# Debian and Ubuntu up to 22.04 name it OVMF_CODE.fd, Ubuntu 24.04 OVMF_CODE_4M.fd
for dir in /usr/share/OVMF /usr/share/ovmf /usr/share/edk2/ovmf; do
    for name in OVMF_CODE_4M.fd OVMF_CODE.fd; do
        if [ -f "$dir/$name" ]; then
            OVMF_CODE="$dir/$name"
            OVMF_VARS="$dir/${name/CODE/VARS}"
            break 2
        fi
    done
done

if [ "$OVMF_CODE" == "" ]; then
    echo "Can't find the OVMF firmware, install it with
    sudo apt install ovmf"
    exit 1
fi

# The firmware writes to its variable store, so it gets a copy of its own kept
# next to the image, which preserves the uefi boot entries between boots.
#
# The store has to be discarded when the image is rebuilt: 'make image' writes a
# new partition table with a new MBR disk signature, so the boot entry recorded
# by the previous boot no longer resolves. The firmware then runs out of boot
# options and drops into its shell instead of falling back to the removable
# \EFI\BOOT\BOOTX64.EFI path.
OVMF_VARS_COPY="$IMAGE_FILE.nvram"
if [ ! -f "$OVMF_VARS_COPY" ] || [ "$IMAGE_FILE" -nt "$OVMF_VARS_COPY" ]; then
    echo "Resetting the uefi variable store for the current $IMAGE_FILE"
    cp -f "$OVMF_VARS" "$OVMF_VARS_COPY"
fi

# A guest behind user mode networking can reach out but nothing can reach in,
# which makes a daemon on it untestable. QEMU_HOSTFWD adds one forward, e.g.
#
#     QEMU_HOSTFWD=tcp::2222-:22 make qemu     then  ssh -p 2222 root@localhost
#
# It is off unless asked for: a port on the host that reaches a machine with a
# known root password should be something you turned on.

# The display is a single virtio-gpu head rather than the default VGA: the
# kernel drives it with KMS, and one head keeps the console where it is looked
# for. The pointer is a USB tablet, which is absolute - the guest cursor tracks
# the host cursor. With only the PS/2 mouse QEMU emulates by default the pointer
# is relative, so the two cursors drift apart until the window is clicked to
# grab input, which looks like a window manager that will not move its windows.

PRETTY_NAME=$(sed -n 's/^PRETTY_NAME="\(.*\)"/\1/p' "$OUT/rootfs/etc/os-release" 2>/dev/null)
echo "Booting $IMAGE_FILE ${PRETTY_NAME:+($PRETTY_NAME) }with $OVMF_CODE"

exec sudo qemu-system-x86_64 \
    -enable-kvm \
    -m ${QEMU_MEMORY:-2048} \
    -smp ${QEMU_CPUS:-4} \
    -machine q35 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$OVMF_VARS_COPY" \
    -drive file="$IMAGE_FILE",format=raw,if=none,id=disk0 \
    -device ahci,id=ahci \
    -device ide-hd,drive=disk0,bus=ahci.0 \
    -netdev user,id=net0${QEMU_HOSTFWD:+,hostfwd=$QEMU_HOSTFWD} \
    -device e1000e,netdev=net0 \
    -vga none \
    -device virtio-gpu-pci \
    -device qemu-xhci \
    -device usb-tablet \
    "$@"

#!/bin/bash
# Boots the produced image with QEMU
set -e

IMAGE_FILE=${IMAGE_FILE:-image.img}

[ -f "$IMAGE_FILE" ] || { echo "'$IMAGE_FILE' is missing, run 'make image' first"; exit 1; }

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
OVMF_VARS_COPY="$IMAGE_FILE.nvram"
[ -f "$OVMF_VARS_COPY" ] || cp -f "$OVMF_VARS" "$OVMF_VARS_COPY"

PRETTY_NAME=$(sed -n 's/^PRETTY_NAME="\(.*\)"/\1/p' rootfs/etc/os-release 2>/dev/null)
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
    -netdev user,id=net0 \
    -device e1000e,netdev=net0 \
    "$@"

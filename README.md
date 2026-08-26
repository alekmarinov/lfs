## Description

This repository contains docker based host system and scripting environment to build bootable iso image with [Linux From Scratch 11.2](https://www.linuxfromscratch.org/lfs/downloads/11.2/LFS-BOOK-11.2.pdf).

## Why

General idea is to learn Linux by building your own system based on the LFS.

## Structure

Scripts are organized to follow closely as possible the book structure.

## Build

To build an image for an arbitrary PC, bootable from USB stick, run

    sudo make image

To build an image bootable with QEMU, run

    sudo make image IMAGE_FILE=lfs-qemu.img ROOT_DEV=/dev/sda2

ROOT_DEV is the device the root partition appears as on the machine the image is booted on.
It is written in /etc/fstab and in the grub menu entry.
The default (/dev/sdb2) is an USB stick plugged in a PC with one internal disk,
while under QEMU the image is the first disk, hence /dev/sda2.

## Usage

Final result is a bootable image (lfs.img) with LFS system which can be flashed on USB stick with the command:
    
    sudo dd if=lfs.img of=/dev/sdb status=progress

Boot the PC from the USB stick and log in as root with the password set by LFS_ROOT_PASSWORD in .env.

## QEMU

The image boots with UEFI only, therefore QEMU needs the OVMF firmware:

    sudo apt install qemu-system-x86 ovmf

Boot lfs-qemu.img with a writable copy of the OVMF variables:

    cp /usr/share/OVMF/OVMF_VARS_4M.fd /tmp/OVMF_VARS.fd
    sudo qemu-system-x86_64 -enable-kvm -m 2048 -smp 4 -machine q35 \
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
        -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd \
        -hda lfs-qemu.img \
        -netdev user,id=n0 -device e1000e,netdev=n0

The OVMF files are named OVMF_CODE.fd and OVMF_VARS.fd on distributions other than Ubuntu 24.04.
The eth0 interface is configured with the address QEMU gives to its user mode network.

## License

The work is based on [Linux from Scratch](http://www.linuxfromscratch.org/lfs) project and provided with MIT license.
The initiative is influenced by Ilya Builuk https://github.com/reinterpretcat/lfs

## Description

This repository contains docker based host system and scripting environment to build bootable iso image with [Linux From Scratch 11.2](https://www.linuxfromscratch.org/lfs/downloads/11.2/LFS-BOOK-11.2.pdf).

## Why

General idea is to learn Linux by building your own system based on the LFS.

## Structure

Scripts are organized to follow closely as possible the book structure.

Every package is built in isolation and archived in packages/, so a distro is
assembled by unpacking a selection of them over a stable core.
The core (distros/core/packages.list) is what an LFS system needs to boot to a
login prompt and is always installed.
A distro is described by its own directory under distros/:

    distros/minimal/distro.conf     identity - name, version, hostname, STRIP
    distros/minimal/packages.list   the packages added on top of the core
    distros/minimal/files/          files copied over the assembled rootfs

## Build

A distro is built in four steps, each one consuming what the previous produced:

    sudo make packages              builds every package from source, once
    make distro DISTRO=minimal      assembles distros/minimal into rootfs/
    make image                      turns rootfs/ into a bootable image.img
    make qemu                       boots image.img

Only one distro is worked on at a time, in the rootfs/ directory.
To start another one, archive the current rootfs first with make docker,
or discard it by passing FORCE=1 to make distro.

## Distro

To see what the assembled rootfs is, read its identity files:

    cat rootfs/etc/os-release       name, version and build id of the distro
    cat rootfs/etc/lfs-distro       which distro was assembled and when

The debug symbols are removed when STRIP=1 in distro.conf, which is what makes
the produced image and docker image small - for the minimal distro it is the
difference between 872 MB and 566 MB. Keep them with

    make distro DISTRO=minimal STRIP=0

To resolve every program of the assembled rootfs against its own libraries, run

    make check

It reports the programs which can not run, which is how a distro missing a
package is found without booting it.

To archive the assembled rootfs as a docker image named after the distro, run

    make docker TAG=20260826

The image is named after the ID of the distro, so the above produces
minimal:20260826 which can be run with

    sudo docker run --rm -it minimal:20260826

## Usage

The produced image.img is flashed on USB stick with the command:

    sudo dd if=image.img of=/dev/sdb status=progress

Boot the PC from the USB stick and log in as root with the password set by
LFS_ROOT_PASSWORD in .env.
The root partition is found by its PARTUUID, so the same image boots from a USB
stick on a PC which already has disks and as the first disk under QEMU.

## QEMU

The image boots with UEFI only, therefore QEMU needs the OVMF firmware:

    sudo apt install qemu-system-x86 ovmf

Then make qemu boots image.img, forwarding QEMU_ARGS to QEMU:

    make qemu
    make qemu QEMU_ARGS="-snapshot"

## License

The work is based on [Linux from Scratch](http://www.linuxfromscratch.org/lfs) project and provided with MIT license.
The initiative is influenced by Ilya Builuk https://github.com/reinterpretcat/lfs

## Description

This repository contains docker based host system and scripting environment to build bootable iso image with [Linux From Scratch 11.2](https://www.linuxfromscratch.org/lfs/downloads/11.2/LFS-BOOK-11.2.pdf).

## Why

General idea is to learn Linux by building your own system based on the LFS.

## Structure

Scripts are organized to follow closely as possible the book structure.

## Build

    sudo make image

## Usage

Final result is a bootable image (lfs.img) with LFS system which can be flashed on USB stick with the command:
    
    sudo dd if=lfs.img of=/dev/sdb status=progress

## License

The work is based on [Linux from Scratch](http://www.linuxfromscratch.org/lfs) project and provided with MIT license.
The initiative is influenced by Ilya Builuk https://github.com/reinterpretcat/lfs

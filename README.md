## Description

This repository contains docker configuration to build bootable iso image with [Linux From Scratch 11.2](https://www.linuxfromscratch.org/lfs/downloads/11.2/LFS-BOOK-11.2.pdf).

## Why

General idea is to learn Linux by building your own system based on the LFS.

## Structure

Scripts are organized to follow closely as possible the book structure.

## Build

Use the following commands:

    docker rm lfs
    docker build -t lfs:11.2 .
    mkdir -pv tmp overlay/{base,package,work,lfs}
    sudo mount -t overlay overlay -olowerdir=overlay/base,upperdir=overlay/package,workdir=overlay/work overlay/lfs
    docker run --privileged --name lfs \
        -v $(pwd)/overlay/lfs:/mnt/lfs \
        -v $(pwd)/overlay/base:/mnt/base \
        -v $(pwd)/overlay/package:/mnt/package \
        -v $(pwd)/tmp:/tmp \
        -v $(pwd)/sources:/mnt/base/sources \
        -v $(pwd)/scripts:/mnt/base/scripts \
        -it --entrypoint bash \
        lfs:11.2
    dd if=tmp/lfs.iso of=/dev/sdb status=progress

Please note, that extended privileges are required by docker container in order to execute some commands (e.g. mount).

### Explaining options

#### -v $(pwd)/overlay/lfs:/mnt/lfs

An overlay of package over the base directory.
All changes in $(pwd)/overlay/lfs will reflect to changes in package directory,
while the base will remain untouched.

#### -v $(pwd)/overlay/base:/mnt/base/base

Directory holding the state before a package get installed.
It represents the lower layer of /mnt/lfs.

#### -v $(pwd)/overlay/package:/mnt/base/package

The upper layer of /mnt/lfs, where the installed files after build remain and will be used to create a binary package.

#### -v $(pwd)/tmp:/tmp

The directory where lfs.img will be produced.

#### -it --entrypoint bash

Replaces the start script allowing you to enter the container with bash.

#### -v $(pwd)/sources:/mnt/base/sources

Optional, mounting this directory will make the downloaded files to persist after the lfs container is removed.

#### -v $(pwd)/scripts:/mnt/base/scripts

Optional, allows to modify the scripts while the container is running for testing purposes.

## Usage

Final result is bootable image with LFS system.

## License

The work is based on [Linux from Scratch](http://www.linuxfromscratch.org/lfs) project and provided with MIT license.
The initiative is influenced by Ilya Builuk https://github.com/reinterpretcat/lfs

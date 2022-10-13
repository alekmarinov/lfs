## Description

This repository contains docker configuration to build bootable iso image with [Linux From Scratch 11.2](https://www.linuxfromscratch.org/lfs/downloads/11.2/LFS-BOOK-11.2.pdf).

## Why

General idea is to learn Linux by building your own system based on the LFS.

## Structure

Scripts are organized to follow closely as possible the book structure.

## Build

Use the following command:

    docker rm lfs
    docker build -t lfs:11.2 .
    docker run --privileged --name lfs -v $(pwd)/sources:/mnt/lfs/sources lfs:11.2
    docker cp lfs:/tmp/lfs.iso .

Please note, that extended privileges are required by docker container in order to execute some commands (e.g. mount).

Use this command to hack:

    docker run -it --privileged --name lfs -v $(pwd)/sources:/mnt/lfs/sources -v $(pwd)/scripts:/mnt/lfs/scripts --entrypoint bash lfs:11.2

## Usage

Final result is bootable iso image with LFS system.

## License

The work is based on [Linux from Scratch](http://www.linuxfromscratch.org/lfs) project and provided with MIT license.
The initiative is influenced by Ilya Builuk https://github.com/reinterpretcat/lfs

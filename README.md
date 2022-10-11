## Description

This repository contains docker configuration to build bootable iso
image with [Linux From Scratch 11.2](https://www.linuxfromscratch.org/lfs/downloads/11.2/LFS-BOOK-11.2.pdf).

## Why

General idea is to learn Linux by building and running LFS system in
isolation from the host system.

## Structure

Scripts are organized in the way of following book structure whenever
it makes sense. Some deviations are done to make a bootable iso image.

## Build

Use the following command:

    docker rm lfs
    docker build -t lfs:11.2 .
    docker run -it --privileged --name lfs -v $(pwd)/sources:/mnt/lfs/sources lfs:11.2
    docker cp lfs:/tmp/lfs.iso .

Please note, that extended privileges are required by docker container
in order to execute some commands (e.g. mount).

Use this command to hack:
    docker run -it --privileged --name lfs -v $(pwd)/sources:/mnt/lfs/sources -v $(pwd)/scripts:/mnt/lfs/scripts
    --entrypoint bash lfs:11.2

## Usage

Final result is bootable iso image with LFS system which, for
example, can be used to load the system inside virtual machine (tested with VirtualBox).

## Troubleshooting

If you have problems with master branch, please try to use stable version from the latest release with toolchain from archive.

## License

This work is based on instructions from [Linux from Scratch](http://www.linuxfromscratch.org/lfs)
project and provided with MIT license.

## Acknowledgement
The scripts structure is borrowed by https://github.com/reinterpretcat/lfs, which was unmaintained at
the time of writing this project.

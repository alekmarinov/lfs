#!/bin/bash

rm -rf overlay/package/*
mount -t overlay overlay \
    -olowerdir=overlay/base,upperdir=overlay/package,workdir=overlay/work \
    overlay/lfs

docker run \
    --rm \
    --privileged \
    --name lfs \
    -v $(pwd)/overlay/lfs:/mnt/lfs \
    -v $(pwd)/overlay/base:/mnt/base \
    -v $(pwd)/overlay/package:/mnt/package \
    -v $(pwd)/tmp:/tmp \
    -t \
    lfs:11.2 \
        /mnt/base/scripts/build.sh $*

umount overlay/lfs

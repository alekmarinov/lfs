#!/bin/bash

export LFS=overlay/lfs
export LFS_PACKAGE=overlay/package
export LFS_BASE=overlay/base
export LC_ALL=POSIX
export MAKEFLAGS="-j4"
export LFS_TGT=x86_64-lfs-linux-gnu
export LFS_TEST=0
export LFS_DOCS=0
export JOB_COUNT=4

rm -rf overlay/package/*
mount -t overlay overlay \
    -olowerdir=overlay/base,upperdir=overlay/package,workdir=overlay/work \
    overlay/lfs
./scripts/build.sh $*
sync
umount overlay/lfs

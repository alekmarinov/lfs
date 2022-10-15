#!/bin/bash
set -e
echo "Start..."

# create sources directory as writable and sticky
RUN mkdir -pv     $LFS_BASE/sources \
 && chmod -v a+wt $LFS_BASE/sources

# make all scripts executable and check environment
RUN chmod -R +x $LFS_BASE/scripts \
    && sync \
    && $LFS_BASE/scripts/2-version-check.sh

# create tools directory and symlink
RUN mkdir -pv $LFS_BASE/{tools,etc,var,tmp,usr/{bin,lib,sbin}} \
    && for i in bin lib sbin; do \
        ln -sv usr/$i $LFS_BASE/$i; \
    done \
    && ln -sv $LFS_BASE/tools / \
    && case $(uname -m) in \
        x86_64) mkdir -pv $LFS_BASE/lib64 ;; \
    esac

# build tools
$LFS/scripts/tools/build-tools.sh

# build rootfs
$LFS/scripts/rootfs/build-rootfs.sh

# build iso image
$LFS/scripts/image/build-image.sh

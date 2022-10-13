#!/bin/bash
set -e
echo "Start..."

# build tools
$LFS/scripts/tools/build-tools.sh

# build rootfs
$LFS/scripts/build/build-rootfs.sh

# build iso image
$LFS/scripts/image/build-image.sh

#!/bin/bash
set -e
echo "Start.."

# prepare to build
sh $LFS/scripts/prepare/run-prepare.sh

# execute rest as root
exec sudo -E -u root /bin/sh - <<EOF
sh $LFS/scripts/build/run-build.sh
# sh $LFS/scripts/image/run-image.sh
EOF

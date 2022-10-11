#!/bin/bash
set -e
echo "Start.."

# prepare to build
sh /tools/prepare/run-prepare.sh

# execute rest as root
exec sudo -E -u root /bin/sh - <<EOF
sh /tools/build/run-build.sh
sh /tools/image/run-image.sh
EOF

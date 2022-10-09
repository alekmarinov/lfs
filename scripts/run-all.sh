#!/bin/bash
set -e
echo "Start.."

# prepare to build
sh /tools/run-prepare.sh

# execute rest as root
exec sudo -E -u root /bin/sh - <<EOF
sh /tools/run-build.sh
sh /tools/run-image.sh
EOF

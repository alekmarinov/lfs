#!/bin/bash
set -e
echo "Start.."

# prepare to build
sh /tools/run-prepare.sh

# execute rest as root
exec sudo -E -u root /bin/sh - <<EOF
# 7.2. Changing Ownership
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/changingowner.html

chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac
# prevent "bad interpreter: Text file busy"
sync
# continue
sh /tools/run-build.sh
sh /tools/run-image.sh
EOF

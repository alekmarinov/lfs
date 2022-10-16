#!/bin/bash
set -e
echo "Creating initial structure.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: < 1 MB"

# 4.2. Structure
# Create a limited directory hierarchy
# https://www.linuxfromscratch.org/lfs/view/stable/chapter04/creatingminlayout.html

mkdir -pv $LFS_BASE/{tools,etc,var,usr/{bin,lib,sbin},tmp}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS_BASE/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS_BASE/lib64 ;;
esac

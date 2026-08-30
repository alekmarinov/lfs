#!/bin/bash
set -e
echo "Cleaning up and Saving the Temporary System.."

# 7.13. Cleaning up and Saving the Temporary System
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/cleanup.html
#
# BUILD_ONLY: deletes the temporary system's leftovers during the build; a
# distro must not replay it
#
# This step only removes files, so its package is nothing but whiteouts. Those
# are meaningful in the build, where they hide files the temporary toolchain
# left behind, but replaying them while assembling a distro means writing a
# whiteout device over a directory a later package created - which fails with
# 'Cannot mknod: File exists' - and would delete the manual pages and
# documentation those later packages install.

rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tmp/*

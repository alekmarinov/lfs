#!/bin/bash
set -e
echo "Cleaning up.."

# 8.79. Cleaning Up
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/cleanup.html

rm -rf /tmp/*
find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
userdel -r tester

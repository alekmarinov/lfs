#!/bin/bash
set -e
echo "Cleaning up and Saving the Temporary System.."

# 7.13. Cleaning up and Saving the Temporary System
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/cleanup.html

rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tmp/*

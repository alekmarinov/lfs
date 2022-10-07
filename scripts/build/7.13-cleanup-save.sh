#!/bin/bash
set -e
echo "Cleaning up and Saving the Temporary System.."

rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools

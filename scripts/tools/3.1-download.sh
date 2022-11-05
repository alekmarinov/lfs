#!/bin/bash
set -e

pushd $LFS_BASE/sources

echo "Checking MD5 sum of the LFS packages.."
if ! md5sum -c lfs-11.2.md5sums; then
    echo "Downloading LFS packages.."
    wget --no-check-certificate --timestamping -c --report-speed=bits --input-file=lfs-11.2.wget-list
    echo "Checking MD5 sum of the LFS packages.."
    md5sum -c lfs-11.2.md5sums
fi

echo "Checking MD5 sum of the BLFS packages.."
if ! md5sum -c blfs-11.2.md5sums; then
    echo "Downloading BLFS packages.."
    wget --no-check-certificate --timestamping -c --report-speed=bits --input-file=blfs-11.2.wget-list
    echo "Checking MD5 sum of the BLFS packages.."
    md5sum -c blfs-11.2.md5sums
fi

popd

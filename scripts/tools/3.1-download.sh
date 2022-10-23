#!/bin/bash
set +e

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

echo "Checking MD5 sum of syslinux package.."
echo "26d3986d2bea109d5dc0e4f8c4822a459276cf021125e8c9f23c3cca5d8c850e syslinux-6.03.tar.xz" | sha256sum -c -
if [ $? -ne 0 ]; then
    echo "Downloading syslinux package.."
    wget --no-check-certificate --timestamping -c --report-speed=bits https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz
    echo "Checking MD5 sum of syslinux package.."
    echo "26d3986d2bea109d5dc0e4f8c4822a459276cf021125e8c9f23c3cca5d8c850e syslinux-6.03.tar.xz" | sha256sum -c -
fi

popd

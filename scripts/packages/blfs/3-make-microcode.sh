#!/bin/bash
# PACKAGE:  microcode
# SOURCE:   microcode-*.tar.gz
# RELEASE:  1
# CLASS:    core
set -e
echo "Building BLFS-CPU microcode.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 30 MB"

# 3. About Firmware - microcode updates for CPUs
#
# The processor reads its microcode from the early initrd before it mounts the
# root file system, so the blobs are packed in /boot/microcode.img which the
# boot loader loads next to the kernel. Both vendors are packed, the kernel
# reads the file matching the CPU it booted on and ignores the other.
#
# The kernel must be built with CONFIG_MICROCODE, CONFIG_MICROCODE_INTEL,
# CONFIG_MICROCODE_AMD and CONFIG_BLK_DEV_INITRD, which it is.
# https://www.linuxfromscratch.org/blfs/view/11.2/postlfs/firmware.html

# 3.1 install the vendor blobs in /lib/firmware
install -v -dm755 /lib/firmware/intel-ucode /lib/firmware/amd-ucode

tar -xf /sources/microcode-*.tar.gz -C /tmp/ \
    && mv /tmp/Intel-Linux-Processor-Microcode-Data-Files-* /tmp/intel-ucode \
    && cp -v /tmp/intel-ucode/intel-ucode/* /lib/firmware/intel-ucode/ \
    && rm -rf /tmp/intel-ucode

cp -v /sources/microcode_amd*.bin /lib/firmware/amd-ucode/

# 3.2 pack the early initrd the boot loader hands to the kernel
#
# GenuineIntel.bin is the concatenation of every intel-ucode blob and
# AuthenticAMD.bin the concatenation of every amd-ucode container, so that the
# image boots on any processor of either vendor rather than on one model.
rm -rf /tmp/initrd
mkdir -pv /tmp/initrd/kernel/x86/microcode
pushd /tmp/initrd

cat /lib/firmware/intel-ucode/* > kernel/x86/microcode/GenuineIntel.bin
cat /lib/firmware/amd-ucode/microcode_amd*.bin > kernel/x86/microcode/AuthenticAMD.bin

echo "Intel microcode: $(du -h kernel/x86/microcode/GenuineIntel.bin | cut -f1)"
echo "AMD microcode:   $(du -h kernel/x86/microcode/AuthenticAMD.bin | cut -f1)"

# the early initrd must be an uncompressed newc cpio, the kernel reads it
# before any decompressor is available
find . | cpio -o -H newc > /boot/microcode.img

popd
rm -rf /tmp/initrd

echo "Packed /boot/microcode.img ($(du -h /boot/microcode.img | cut -f1))"

#!/bin/bash
# PACKAGE:  linux-firmware-iwlwifi
# SOURCE:   iwlwifi-7265D-*.ucode
# RELEASE:  1
# CLASS:    extra
set -e
echo "Installing the iwlwifi firmware.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 2 MB"

# 9. iwlwifi firmware
# The intel wireless chips carry no firmware of their own: the driver uploads it
# at probe time and refuses to bring the device up without it. iwlwifi asks the
# kernel for a range of api revisions, newest first, and takes the first that is
# present - for the 7265D that range is 22 to 29, so the 29 file covers it.
#
# NOTE only the one blob this hardware needs is shipped, not the whole of
# linux-firmware, which is a quarter of a gigabyte against a two gigabyte image.
# A machine with a different wireless chip will find no firmware here and its
# driver will log 'no suitable firmware found'. Add the file it asks for to
# sources/blfs-11.2.extra-list and to the md5sums, then extend the list below.
#
# BUILD_REQUIRES:
# RUNTIME_REQUIRES:
install -v -d -m755 /lib/firmware
install -v -m644 /sources/iwlwifi-7265D-29.ucode /lib/firmware/

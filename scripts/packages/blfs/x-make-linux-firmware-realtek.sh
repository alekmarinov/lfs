#!/bin/bash
set -e
echo "Installing the Realtek ethernet firmware.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: less than 1 MB"

# 9. Realtek ethernet firmware
# The RTL8168/8111 chips carry no firmware of their own. Without it the driver
# still attaches, the PHY negotiates and the link comes up, so the interface
# looks healthy - but the chip cannot transmit. On the ROG laptop that showed
# as eth0 with RX bytes climbing and TX bytes stuck at 0, a link that flapped
# up and down, and dhcpcd sending DISCOVERs that never reached the wire, so
# the machine never got an address.
#
# The kernel names the exact file it wants, one per chip revision:
#   r8169 0000:03:00.0: Unable to load firmware rtl_nic/rtl8168h-2.fw (-2)
#
# NOTE the whole rtl_nic set is 48K, so the RTL8168 family is shipped rather
# than only the one revision this laptop asks for - a different board in the
# same family would otherwise fail the same way, and the size is nothing
# against a 3G image. Other families are not here: read the file name out of
# dmesg as above, add it to sources/blfs-11.2.wget-list and the md5sums, and
# extend the list below.
#
# BUILD_REQUIRES:
# RUNTIME_REQUIRES:
install -v -d -m755 /lib/firmware/rtl_nic
for fw in rtl8168h-1 rtl8168h-2 rtl8168g-2 rtl8168g-3 rtl8168f-1 rtl8168f-2 \
          rtl8168e-2 rtl8168e-3 rtl8411-2 rtl8106e-1; do
    install -v -m644 /sources/$fw.fw /lib/firmware/rtl_nic/
done

# The blob the reporting hardware asks for must be where the driver looks.
test -f /lib/firmware/rtl_nic/rtl8168h-2.fw
echo "realtek nic firmware installed"

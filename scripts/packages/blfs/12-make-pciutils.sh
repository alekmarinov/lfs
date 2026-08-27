#!/bin/bash
set -e
echo "Building BLFS-PCI Utils.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 8.5 MB"

# 12. PCI Utils
# The PCI Utils package contains a set of programs for listing PCI devices,
# inspecting their status and setting their configuration registers.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/pciutils.html
#
# NOTE update-pciids refreshes /usr/share/hwdata/pci.ids from the network,
# the pci.ids shipped in the tarball is installed instead.

tar -xf /sources/pciutils-*.tar.xz -C /tmp/ \
    && mv /tmp/pciutils-* /tmp/pciutils \
    && pushd /tmp/pciutils \
    && make PREFIX=/usr SHAREDIR=/usr/share/hwdata SHARED=yes \
    && make PREFIX=/usr SHAREDIR=/usr/share/hwdata SHARED=yes install install-lib \
    && chmod -v 755 /usr/lib/libpci.so \
    && popd \
    && rm -rf /tmp/pciutils

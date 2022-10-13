#!/bin/bash
set -e
echo "Building linux kernel.."
echo "Approximate build time: 1.5 - 130.0 SBU (typically about 12 SBU)"
echo "Required disk space: 1200 - 8800 MB (typically about 1700 MB)"

# 10.3. Linux
# The Linux package contains the Linux kernel.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter10/kernel.html

tar -xf /sources/linux-*.tar.xz -C /tmp/ \
    && mv /tmp/linux-* /tmp/linux \
    && pushd /tmp/linux

# ensure proper ownership of the files
chown -R 0:0 .

# 10.3.1. Installation of the kernel

# clean source tree
make mrproper

# copy premade config
# NOTE manual way is by launching:
# make menuconfig
cp /sources/kernel-5.19.2.config .config

# compile
make

# installation
make modules_install

# copy kernel image
VER=$(ls /sources/linux-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-$VER-lfs-11.2
# copy symbols
cp -iv System.map /boot/System.map-$VER
# copy original configuration
cp -iv .config /boot/config-$VER
# install documentation
if [ $LFS_DOCS -eq 1 ]; then
    install -d /usr/share/doc/linux-$VER
    cp -r Documentation/* /usr/share/doc/linux-$VER
fi

# 10.3.2. Configuring Linux Module Load Order
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

popd \
  && rm -rf /tmp/linux

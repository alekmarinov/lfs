#!/bin/bash
set -e
echo "Building grub.."
echo "Approximate build time: 0.7 SBU"
echo "Required disk space: 159 MB"

# 8.60. GRUB
# The GRUB package contains the GRand Unified Bootloader.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/grub.html

tar -xf /sources/grub-*.tar.xz -C /tmp/ \
    && mv /tmp/grub-* /tmp/grub \
    && pushd /tmp/grub \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-efiemu \
        --disable-werror \
    && make \
    && make install \
    && mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions \
    && popd \
    && rm -rf /tmp/grub

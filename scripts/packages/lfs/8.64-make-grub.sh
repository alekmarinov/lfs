#!/bin/bash
# PACKAGE:  grub
# SOURCE:   grub-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building grub.."
echo "Approximate build time: 0.7 SBU"
echo "Required disk space: 159 MB"

# 8.60. GRUB
# The GRUB package contains the GRand Unified Bootloader.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/grub.html
#
# NOTE extra_deps.lst is written by hand because grub 2.12 lists it as a
# prerequisite of syminfo.lst without shipping a rule that builds it, so
# make stops partway through grub-core. The words in it are literal.

tar -xf /sources/grub-*.tar.xz -C /tmp/ \
    && mv /tmp/grub-* /tmp/grub \
    && pushd /tmp/grub \
    && unset {C,CPP,CXX,LD}FLAGS \
    && echo depends bli part_gpt > grub-core/extra_deps.lst \
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

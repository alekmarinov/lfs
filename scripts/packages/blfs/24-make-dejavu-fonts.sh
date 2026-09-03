#!/bin/bash
# PACKAGE:  dejavu-fonts
# SOURCE:   dejavu-fonts-ttf-*.tar.bz2
# RELEASE:  1
# CLASS:    extra
set -e
echo "Installing BLFS-DejaVu fonts.."
echo "Required disk space: 10 MB"

# 24. TTF and OTF fonts - DejaVu
# The X core fonts are bitmap and Type1 only. DejaVu gives fontconfig a
# scalable family, which is what Xft renders with - xterm and every toolkit
# text look like a current system rather than a bitmap terminal.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/tuning-fontconfig.html

rm -rf /tmp/dejavu
tar -xf /sources/dejavu-fonts-ttf-*.tar.bz2 -C /tmp/
mv /tmp/dejavu-fonts-ttf-* /tmp/dejavu
pushd /tmp/dejavu

install -v -d -m755 /usr/share/fonts/dejavu
install -v -m644 ttf/*.ttf /usr/share/fonts/dejavu
fc-cache -v /usr/share/fonts/dejavu

popd
rm -rf /tmp/dejavu

echo "Installed $(ls /usr/share/fonts/dejavu/*.ttf | wc -l) DejaVu faces"

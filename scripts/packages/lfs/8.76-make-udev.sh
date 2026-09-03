#!/bin/bash
# PACKAGE:  udev
# SOURCE:   systemd-*.tar.gz
# RELEASE:  1
# CLASS:    core
set -e
echo "Building udev.."

# 8.76. Udev from Systemd
# Device management. This replaces eudev, which LFS carried until 12.x and
# which upstream has stopped maintaining: udev is now taken out of the systemd
# source and built on its own, without systemd itself.
#
# The build needs three tarballs rather than one - the systemd source, a set of
# LFS specific rules and helpers, and the man pages, which are shipped
# separately because building them would pull in the whole documentation
# toolchain.
#
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/udev.html
#
# BUILD_REQUIRES: 8.57-make-meson 8.56-make-ninja 8.9-make-lz4 8.19-make-pkgconf 8.26-make-libcap
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

SD_VER=$(basename /sources/systemd-*.tar.gz .tar.gz | sed 's/systemd-//')

rm -rf /tmp/systemd
tar -xf /sources/systemd-*.tar.gz -C /tmp/
mv /tmp/systemd-* /tmp/systemd
pushd /tmp/systemd

# render is not a group this system has, and the sgx rules refer to devices it
# does not create
sed -e 's/GROUP="render"/GROUP="video"/' \
    -e 's/GROUP="sgx", //' \
    -i rules.d/50-udev-default.rules.in

# systemd-sysctl is part of systemd, which is not being built
sed -i '/systemd-sysctl/s/^/#/' rules.d/99-systemd.rules.in

sed -e '/NETWORK_DIRS/s/systemd/udev/' \
    -i src/libsystemd/sd-network/network-util.h

mkdir -p build
pushd build

meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      -D mode=release \
      -D dev-kvm-mode=0660 \
      -D link-udev-shared=false \
      -D logind=false \
      -D vconsole=false

# only the udev parts of systemd are built, named explicitly
export udev_helpers=$(grep "'name' :" ../src/udev/meson.build | \
                      awk '{print $3}' | tr -d ",'" | grep -v 'udevadm')

ninja udevadm systemd-hwdb \
      $(ninja -n | grep -Eo '(src/(lib)?udev|rules.d|hwdb.d)/[^ ]*') \
      $(realpath libudev.so --relative-to .) \
      $udev_helpers

install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}                 /usr/lib/
install -vm644 ../src/libudev/libudev.h            /usr/include/
install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf               /etc/udev/
install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/
install -vm644 $(find ../rules.d/*.rules \
                      -not -name '*power-switch*') /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/
install -vm755 $udev_helpers                       /usr/lib/udev
install -vm644 ../network/99-default.link          /usr/lib/udev/network

# the LFS specific rules and helper scripts
tar -xf /sources/udev-lfs-*.tar.xz
make -f udev-lfs-*/Makefile.lfs install

# man pages, shipped ready built
tar -xf /sources/systemd-man-pages-*.tar.xz \
    --no-same-owner --strip-components=1 \
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*' \
                                  '*/systemd.link.5' \
                                  '*/systemd-'{hwdb,udevd.service}.8

sed 's|systemd/network|udev/network|' \
    /usr/share/man/man5/systemd.link.5 \
  > /usr/share/man/man5/udev.link.5

sed 's/systemd\(\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8 \
                             > /usr/share/man/man8/udev-hwdb.8

sed 's|lib.*udevd|sbin/udevd|' \
    /usr/share/man/man8/systemd-udevd.service.8 \
  > /usr/share/man/man8/udevd.8

rm -f /usr/share/man/man*/systemd*

unset udev_helpers

udev-hwdb update

popd
popd
rm -rf /tmp/systemd

#!/bin/bash
# PACKAGE:  dbus
# SOURCE:   dbus-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-D-Bus.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 82 MB"

# 12. D-Bus
# D-Bus is a message bus system, a simple way for applications to talk to one another.
# https://www.linuxfromscratch.org/blfs/view/12.4/general/dbus.html

VER=$(ls /sources/dbus-*.tar.xz | sed 's/^[^-]*-//' | sed 's/\.tar\.xz$//')

# the user the message bus daemon runs as
groupadd -g 18 messagebus 2>/dev/null || true
useradd -c "D-Bus Message Daemon User" -d /run/dbus -u 18 \
        -g messagebus -s /bin/false messagebus 2>/dev/null || true

# NOTE dbus 1.16 builds with meson; the autotools build was removed upstream.
# The path options the old recipe passed (--sysconfdir, --localstatedir,
# --runstatedir, --with-system-socket) are meson defaults here, so the
# configuration below is the book's rather than a translation of the old flags.
rm -rf /tmp/dbus
tar -xf /sources/dbus-*.tar.xz -C /tmp/
mv /tmp/dbus-* /tmp/dbus
pushd /tmp/dbus
mkdir build
cd build
meson setup --prefix=/usr \
    --buildtype=release \
    --wrap-mode=nofallback \
    -D systemd=disabled \
    ..
ninja
ninja install

# the launch helper is setuid root and group messagebus, which is what lets an
# unprivileged process start a service on the system bus
chown -v root:messagebus /usr/libexec/dbus-daemon-launch-helper
chmod -v 4750 /usr/libexec/dbus-daemon-launch-helper
popd
rm -rf /tmp/dbus

# the machine identifier the bus is keyed by
dbus-uuidgen --ensure

# the dbus boot script comes from the BLFS bootscripts unpacked in /tmp
# Unpack the bootscripts here unless an earlier package left them behind:
# every package builds in its own overlay, so /tmp is not a reliable way to
# hand a tree from one package to the next.
[ -d /tmp/blfs-bootscripts ] \
    || { tar -xf /sources/blfs-bootscripts-*.tar.xz -C /tmp/ \
         && mv /tmp/blfs-bootscripts-* /tmp/blfs-bootscripts; }

pushd /tmp/blfs-bootscripts \
    && make install-dbus \
    && popd

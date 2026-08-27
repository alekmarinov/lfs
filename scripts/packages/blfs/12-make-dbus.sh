#!/bin/bash
set -e
echo "Building BLFS-D-Bus.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 82 MB"

# 12. D-Bus
# D-Bus is a message bus system, a simple way for applications to talk to one another.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/dbus.html

VER=$(ls /sources/dbus-*.tar.xz | sed 's/^[^-]*-//' | sed 's/\.tar\.xz$//')

# the user the message bus daemon runs as
groupadd -g 18 messagebus 2>/dev/null || true
useradd -c "D-Bus Message Daemon User" -d /run/dbus -u 18 \
        -g messagebus -s /bin/false messagebus 2>/dev/null || true

tar -xf /sources/dbus-*.tar.xz -C /tmp/ \
    && mv /tmp/dbus-* /tmp/dbus \
    && pushd /tmp/dbus \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --runstatedir=/run \
        --enable-user-session \
        --disable-doxygen-docs \
        --disable-xml-docs \
        --disable-static \
        --with-systemduserunitdir=no \
        --with-systemdsystemunitdir=no \
        --docdir=/usr/share/doc/dbus-$VER \
        --with-system-socket=/run/dbus/system_bus_socket \
    && make \
    && make install \
    && chown -v root:messagebus /usr/libexec/dbus-daemon-launch-helper \
    && chmod -v 4750 /usr/libexec/dbus-daemon-launch-helper \
    && popd \
    && rm -rf /tmp/dbus

# the machine identifier the bus is keyed by
dbus-uuidgen --ensure

# the dbus boot script comes from the BLFS bootscripts unpacked in /tmp
pushd /tmp/blfs-bootscripts \
    && make install-dbus \
    && popd

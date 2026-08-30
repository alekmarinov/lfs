#!/bin/bash
set -e
echo "Building BLFS-acpid.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 4.8 MB"

# 12. acpid
# The acpid daemon dispatches the ACPI events the kernel reports, so that
# pressing the power button shuts the machine down instead of being ignored.
# Under QEMU it is what makes 'system_powerdown' work.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/acpid.html

VER=$(ls /sources/acpid-*.tar.xz | sed 's/^[^-]*-//' | sed 's/\.tar\.xz$//')
tar -xf /sources/acpid-*.tar.xz -C /tmp/ \
    && mv /tmp/acpid-* /tmp/acpid \
    && pushd /tmp/acpid \
    && ./configure \
        --prefix=/usr \
        --docdir=/usr/share/doc/acpid-$VER \
    && make \
    && make install \
    && install -v -m755 -d /etc/acpi/events \
    && if [ $LFS_DOCS -eq 1 ]; then cp -r samples /usr/share/doc/acpid-$VER; fi \
    && popd \
    && rm -rf /tmp/acpid

# The power button shuts the system down. Without this event acpid runs but
# does nothing, the kernel reports the button press and nobody acts on it.
cat > /etc/acpi/events/power << "EOF"
# Begin /etc/acpi/events/power

event=button/power
action=/etc/acpi/power.sh

# End /etc/acpi/events/power
EOF

cat > /etc/acpi/power.sh << "EOF"
#!/bin/sh
# Shut the system down when the power button is pressed
/sbin/shutdown -h now
EOF
chmod -v 755 /etc/acpi/power.sh

# the acpid boot script comes from the BLFS bootscripts unpacked in /tmp
# Unpack the bootscripts here unless an earlier package left them behind:
# every package builds in its own overlay, so /tmp is not a reliable way to
# hand a tree from one package to the next.
[ -d /tmp/blfs-bootscripts ] \
    || { tar -xf /sources/blfs-bootscripts-*.tar.xz -C /tmp/ \
         && mv /tmp/blfs-bootscripts-* /tmp/blfs-bootscripts; }

pushd /tmp/blfs-bootscripts \
    && make install-acpid \
    && popd

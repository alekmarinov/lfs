#!/bin/bash
# PACKAGE:  sysklogd
# SOURCE:   sysklogd-*.tar.gz
# RELEASE:  1
# CLASS:    core
set -e
echo "Building sysklogd.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 0.6 MB"

# 8.81. Sysklogd
# The sysklogd package contains programs for logging system messages,
# such as those given by the kernel when unusual things happen.
# https://www.linuxfromscratch.org/lfs/view/12.4/chapter08/sysklogd.html
#
# NOTE sysklogd 2.x is a different program from the 1.5 this recipe used to
# build. It configures with autotools instead of being driven by make
# variables, and the two source edits that used to be needed - one around
# 'Error loading kernel symbols' in ksym_mod.c, one replacing 'union wait' in
# syslogd.c - refer to files 2.x does not have.
#
# NOTE the '|| exit 1'. Commands follow the build chain, and a failing && chain
# does not trip 'set -e', so without it a broken build fell through to writing
# syslog.conf and the package was recorded as passed while installing no
# syslogd at all - which showed up only as the log daemon failing to start.

VER=$(ls /sources/sysklogd-*.tar.gz | sed 's/^[^0-9]*//; s/\.tar\.gz$//')

rm -rf /tmp/sysklogd
tar -xf /sources/sysklogd-*.tar.gz -C /tmp/ \
    && mv /tmp/sysklogd-* /tmp/sysklogd \
    && pushd /tmp/sysklogd \
    && ./configure \
        --prefix=/usr      \
        --sysconfdir=/etc  \
        --runstatedir=/run \
        --without-logger   \
        --disable-static   \
        --docdir=/usr/share/doc/sysklogd-$VER \
    && make \
    && make install \
    && popd \
    || exit 1

# 8.81.2. Configuring Sysklogd
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# Do not open any internet ports.
secure_mode 2

# End /etc/syslog.conf
EOF

rm -rf /tmp/sysklogd

# The daemon the bootscripts start must actually be there.
test -x /usr/sbin/syslogd
echo "syslogd installed"

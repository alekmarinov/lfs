#!/bin/bash
# PACKAGE:  openssh
# SOURCE:   openssh-*.tar.gz
# RELEASE:  3
# CLASS:    system
set -e
echo "Building BLFS-OpenSSH.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 51 MB"

# 4. OpenSSH
# The OpenSSH package contains ssh clients and the sshd daemon, used for
# encrypted communication between hosts.
# optional: linux-pam
# https://www.linuxfromscratch.org/blfs/view/11.2/postlfs/openssh.html
#
# NOTE /tmp/openssh is removed first. An earlier failed build can leave the
# directory behind, and 'mv openssh-<version> /tmp/openssh' then moves the new
# source inside the old tree instead of becoming it - so the build silently
# uses the previous version.
#
# NOTE the '|| exit 1' at the end of the build. More commands follow it, and
# a failing && chain does not trip 'set -e', so without it a broken build fell
# through to the bootscript install below and the package was recorded as
# passed while containing no ssh binaries at all.

VER=$(ls /sources/openssh-*.tar.gz | sed 's/^[^-]*-//' | sed 's/\.tar\.gz$//')

# the privilege separation environment sshd drops into
install -v -m700 -d /var/lib/sshd
chown -v root:sys /var/lib/sshd
# The privilege separation account, recreated rather than merely ensured.
#
# 'useradd ... || true' looks right and is not: the build base is cumulative,
# so from the second build onwards the account already exists, useradd does
# nothing, /etc/passwd is never written, and the overlay captures no change.
# The package then ships no passwd line at all, and whether an image ends up
# with an sshd user depends on which unrelated package last happened to
# snapshot the base - 8.85-clean has one, and it is not in every distro.
# The minimal image had no sshd user, and sshd refused to start with
# "Privilege separation user sshd does not exist".
#
# Deleting first makes the write happen, so the line lands in this package's
# /etc/passwd, /etc/group and /etc/shadow - which file-policy.conf merges
# line by line into the assembled image. That is order independent, which the
# previous arrangement was not.
userdel  sshd 2>/dev/null || true
groupdel sshd 2>/dev/null || true
groupadd -g 50 sshd
useradd -c 'sshd PrivSep' -d /var/lib/sshd -g sshd -s /bin/false -u 50 sshd
grep -q '^sshd:' /etc/passwd || { echo "sshd user was not created"; exit 1; }

rm -rf /tmp/openssh
tar -xf /sources/openssh-*.tar.gz -C /tmp/ \
    && mv /tmp/openssh-* /tmp/openssh \
    && pushd /tmp/openssh \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc/ssh \
        --with-privsep-path=/var/lib/sshd \
        --with-default-path=/usr/bin \
        --with-superuser-path=/usr/sbin:/usr/bin \
        --with-pid-dir=/run \
    && make \
    && rm -f /etc/ssh/sshd_config /etc/ssh/ssh_config /etc/ssh/moduli \
    && make install \
    && test -f /etc/ssh/sshd_config \
    && install -v -m755 contrib/ssh-copy-id /usr/bin \
    && install -v -m644 contrib/ssh-copy-id.1 /usr/share/man/man1 \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -m755 -d /usr/share/doc/openssh-$VER; \
        install -v -m644 INSTALL LICENCE OVERVIEW README* /usr/share/doc/openssh-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/openssh \
    || exit 1

# the sshd boot script comes from the BLFS bootscripts unpacked in /tmp
# Unpack the bootscripts here unless an earlier package left them behind:
# every package builds in its own overlay, so /tmp is not a reliable way to
# hand a tree from one package to the next.
[ -d /tmp/blfs-bootscripts ] \
    || { tar -xf /sources/blfs-bootscripts-*.tar.xz -C /tmp/ \
         && mv /tmp/blfs-bootscripts-* /tmp/blfs-bootscripts; }

pushd /tmp/blfs-bootscripts \
    && make install-sshd \
    && popd

# NOTE the config files are deleted immediately before 'make install'.
#
# openssh's install-sysconf target installs sshd_config, ssh_config and moduli
# only when they are NOT already present - it will not overwrite a config an
# administrator may have edited. The build base is cumulative, so from the
# second build of this package onwards they were always already there, the
# install step skipped them, and the overlay upper captured nothing. The
# package therefore shipped an empty /etc/ssh and every image built from it
# had no sshd_config at all.
#
# The symptom is not subtle but it is late: the image boots, and S30sshd stops
# with "/etc/ssh/sshd_config: No such file or directory" and then waits at
# "Press Enter to continue...", so an unattended boot never reaches a login.
# Deleting them first makes the install write them again, into the overlay,
# where they belong to this package. The test -f above refuses to archive a
# package which somehow still lacks the config.

# The host keys are this machine's identity, and 'make install' above ran
# 'ssh-keygen -A' as part of its own install rules. Left alone, one set of
# private keys is baked into the package and from there into every image ever
# built from it: every device answering with the same fingerprint, and the
# private half sitting in a build tree. Remove them, and have the boot script
# make its own the first time it starts - which is what an appliance needs and
# costs a second once per device.
rm -f /etc/ssh/ssh_host_*

sed -i 's|^        log_info_msg "Starting SSH Server\.\.\."|        if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then\n            log_info_msg "Generating SSH host keys..."\n            ssh-keygen -A >/dev/null 2>\&1\n            evaluate_retval\n        fi\n\n&|' /etc/rc.d/init.d/sshd

grep -q "ssh-keygen -A" /etc/rc.d/init.d/sshd || { echo "the sshd boot script was not patched"; exit 1; }
grep -q 'log_info_msg "Starting SSH Server' /etc/rc.d/init.d/sshd || { echo "the patch ate the start line"; exit 1; }
sh -n /etc/rc.d/init.d/sshd || { echo "the patched sshd boot script is not valid shell"; exit 1; }

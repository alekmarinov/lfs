#!/bin/bash
set -e
echo "Building BLFS-OpenSSH.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 51 MB"

# 4. OpenSSH
# The OpenSSH package contains ssh clients and the sshd daemon, used for
# encrypted communication between hosts.
# optional: linux-pam
# https://www.linuxfromscratch.org/blfs/view/11.2/postlfs/openssh.html

VER=$(ls /sources/openssh-*.tar.gz | sed 's/^[^-]*-//' | sed 's/\.tar\.gz$//')

# the privilege separation environment sshd drops into
install -v -m700 -d /var/lib/sshd
chown -v root:sys /var/lib/sshd
groupadd -g 50 sshd 2>/dev/null || true
useradd -c 'sshd PrivSep' -d /var/lib/sshd -g sshd -s /bin/false -u 50 sshd 2>/dev/null || true

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
    && make install \
    && install -v -m755 contrib/ssh-copy-id /usr/bin \
    && install -v -m644 contrib/ssh-copy-id.1 /usr/share/man/man1 \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -m755 -d /usr/share/doc/openssh-$VER; \
        install -v -m644 INSTALL LICENCE OVERVIEW README* /usr/share/doc/openssh-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/openssh

# the sshd boot script comes from the BLFS bootscripts unpacked in /tmp
pushd /tmp/blfs-bootscripts \
    && make install-sshd \
    && popd

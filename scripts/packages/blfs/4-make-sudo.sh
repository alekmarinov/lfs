#!/bin/bash
set -e
echo "Building BLFS-Sudo.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 60 MB"

# 4. Sudo
# The Sudo package allows a system administrator to give certain users the
# ability to run some commands as root or another user.
# optional: linux-pam
# https://www.linuxfromscratch.org/blfs/view/11.2/postlfs/sudo.html
#
# NOTE -std=gnu17. sudo declares plugin entry points as 'int (*)()', meaning
# an unspecified argument list. C23 reads that as 'no arguments', so assigning
# the real functions to those fields becomes a pointer type mismatch.

VER=$(ls /sources/sudo-*.tar.gz | sed 's/^[^-]*-//' | sed 's/\.tar\.gz$//')
tar -xf /sources/sudo-*.tar.gz -C /tmp/ \
    && mv /tmp/sudo-* /tmp/sudo \
    && pushd /tmp/sudo \
    && CC='gcc -std=gnu17' ./configure \
        --prefix=/usr \
        --libexecdir=/usr/lib \
        --with-secure-path \
        --with-all-insults \
        --with-env-editor \
        --docdir=/usr/share/doc/sudo-$VER \
        --with-passprompt="[sudo] password for %p: " \
    && make \
    && make install \
    && ln -sfv libsudo_util.so.0.0.0 /usr/lib/sudo/libsudo_util.so.0 \
    && popd \
    && rm -rf /tmp/sudo

# members of the wheel group may run any command
cat > /etc/sudoers.d/00-sudo << "EOF2"
Defaults secure_path="/usr/sbin:/usr/bin"
%wheel ALL=(ALL) ALL
EOF2

# sudo authenticates through PAM
cat > /etc/pam.d/sudo << "EOF2"
# Begin /etc/pam.d/sudo

auth      include     system-auth
account   include     system-account
session   required    pam_env.so
session   include     system-session

# End /etc/pam.d/sudo
EOF2
chmod 644 /etc/pam.d/sudo

#!/bin/bash
set -e
echo "Building BLFS-Linux-PAM.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 39 MB"

# 4. Linux-PAM
# The Linux PAM package contains Pluggable Authentication Modules used to enable
# the local system administrator to choose how applications authenticate users.
# optional: db,libnsl,libtirpc
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/linux-pam.html

VER=$(ls /sources/Linux-PAM-*.tar.xz | head -1 | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/Linux-PAM-$VER.tar.xz -C /tmp/ \
    && mv /tmp/Linux-PAM-* /tmp/linuxpam \
    && pushd /tmp/linuxpam \
    && sed -e /service_DATA/d -i modules/pam_namespace/Makefile.am \
    && autoreconf \
    && if [ $LFS_DOCS -eq 1 ]; then \
        tar -xf /sources/Linux-PAM-$VER-docs.tar.xz --strip-components=1; \
    fi \
    && ./configure \
        --prefix=/usr \
        --sbindir=/usr/sbin \
        --sysconfdir=/etc \
        --libdir=/usr/lib \
        --enable-securedir=/usr/lib/security \
        --docdir=/usr/share/doc/Linux-PAM-$VER \
    && make \
    && install -v -m755 -d /etc/pam.d

if [ $LFS_TEST -eq 1 ]; then
    cat > /etc/pam.d/other << "EOF"
auth     required       pam_deny.so
account  required       pam_deny.so
password required       pam_deny.so
session  required       pam_deny.so
EOF
    make check
    rm -fv /etc/pam.d/other
fi

make install \
    && chmod -v 4755 /usr/sbin/unix_chkpwd \
    && popd \
    && rm -rf /tmp/linuxpam

# Configure pam

install -vdm755 /etc/pam.d
cat > /etc/pam.d/system-account << "EOF"
# Begin /etc/pam.d/system-account

account   required    pam_unix.so

# End /etc/pam.d/system-account
EOF

cat > /etc/pam.d/system-auth << "EOF"
# Begin /etc/pam.d/system-auth

auth      required    pam_unix.so

# End /etc/pam.d/system-auth
EOF

cat > /etc/pam.d/system-session << "EOF"
# Begin /etc/pam.d/system-session

session   required    pam_unix.so

# End /etc/pam.d/system-session
EOF

cat > /etc/pam.d/system-password << "EOF"
# Begin /etc/pam.d/system-password

# use sha512 hash for encryption, use shadow, and try to use any previously
# defined authentication token (chosen password) set by any prior module
password  required    pam_unix.so       sha512 shadow try_first_pass

# End /etc/pam.d/system-password
EOF

# FIXME: If you wish to enable strong password support, 
# install libpwquality, and follow the instructions in that page
# to configure the pam_pwquality PAM module with strong password support.


# With this file, programs that are PAM aware will not run 
# unless a configuration file specifically for that application is created.
cat > /etc/pam.d/other << "EOF"
# Begin /etc/pam.d/other

auth        required        pam_warn.so
auth        required        pam_deny.so
account     required        pam_warn.so
account     required        pam_deny.so
password    required        pam_warn.so
password    required        pam_deny.so
session     required        pam_warn.so
session     required        pam_deny.so

# End /etc/pam.d/other
EOF


#!/bin/bash
# PACKAGE:  linux-pam
# SOURCE:   Linux-PAM-[0-9]*[0-9].tar.xz
# VERSION:  1.7.1
# RELEASE:  1
# CLASS:    system
set -e
echo "Building BLFS-Linux-PAM.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 39 MB"

# 4. Linux-PAM
# The Linux PAM package contains Pluggable Authentication Modules used to enable
# the local system administrator to choose how applications authenticate users.
# optional: db,libnsl,libtirpc
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/linux-pam.html
#
# BUILD_REQUIRES: 8.28-make-shadow

# NOTE the glob is the pinned one, not 'Linux-PAM-*.tar.xz'.
#
# The loose glob matched the docs tarball too, and 'ls | head -1' then picked
# whichever sorted first - which was Linux-PAM-1.5.2-docs.tar.xz, so VER came
# out as the version of a stale docs archive rather than of the package being
# built, and the extract looked for a tarball that no longer exists.
# '[0-9]*[0-9].tar.xz' cannot match '-docs.tar.xz' because that does not end
# in a digit before the extension.
VER=$(basename "$(ls /sources/Linux-PAM-[0-9]*[0-9].tar.xz)" .tar.xz | sed 's/^Linux-PAM-//')
# NOTE Linux-PAM 1.7 builds with meson; the autotools build was removed
# upstream, so there is no configure and no Makefile.am. That retires two
# steps rather than porting them: the 'autoreconf', and the
# 'sed /service_DATA/d modules/pam_namespace/Makefile.am' which existed to
# stop a systemd service file being installed - meson does not install one.
#
# The path options the old configure needed are meson defaults here, so only
# docdir is passed, as the book does.
rm -rf /tmp/linuxpam
tar -xf /sources/Linux-PAM-$VER.tar.xz -C /tmp/ \
    && mv /tmp/Linux-PAM-$VER /tmp/linuxpam \
    && pushd /tmp/linuxpam \
    && if [ $LFS_DOCS -eq 1 ]; then \
        tar -xf /sources/Linux-PAM-$VER-docs.tar.xz --strip-components=1; \
    fi \
    && mkdir build \
    && cd build \
    && meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D docdir=/usr/share/doc/Linux-PAM-$VER \
    && ninja \
    && install -v -m755 -d /etc/pam.d \
    || exit 1

if [ $LFS_TEST -eq 1 ]; then
    cat > /etc/pam.d/other << "EOF"
auth     required       pam_deny.so
account  required       pam_deny.so
password required       pam_deny.so
session  required       pam_deny.so
EOF
    ninja test || true
    rm -fv /etc/pam.d/other
fi

ninja install \
    && chmod -v 4755 /usr/sbin/unix_chkpwd \
    && popd \
    && rm -rf /tmp/linuxpam \
    || exit 1

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


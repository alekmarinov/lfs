#!/bin/bash
set -e
echo "Building BLFS-shadow.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 36 MB"

# 4. shadow
# Shadow was indeed installed in LFS and there is no reason to reinstall it unless
# you installed CrackLib or Linux-PAM after your LFS system was completed.
# If you have installed CrackLib after LFS, then reinstalling Shadow will enable 
# strong password support. If you have installed Linux-PAM, reinstalling Shadow 
# will allow programs such as login and su to utilize PAM.
# required: linux-pam|cracklib
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/shadow.html

VER=$(ls /sources/shadow-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/shadow-*.tar.xz -C /tmp/ \
    && mv /tmp/shadow-* /tmp/shadow \
    && pushd /tmp/shadow \
    && sed -i 's/groups$(EXEEXT) //' src/Makefile.in \
    && find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \; \
    && find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \; \
    && find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \; \
    && sed -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
        -e 's@/var/spool/mail@/var/mail@' \
        -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
        -i etc/login.defs \
    && ./configure \
        --sysconfdir=/etc \
        --disable-static \
        --with-group-name-max-length=32 \
    && make \
    && make exec_prefix=/usr install \
    && popd \
    && rm -rf /tmp/shadow

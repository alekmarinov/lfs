#!/bin/bash
# PACKAGE:  shadow
# SOURCE:   shadow-*.tar.xz
# RELEASE:  1
# CLASS:    core
set -e
echo "Building Shadow.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 46 MB"

# 8.25. Shadow
# The Shadow package contains programs for handling passwords in a secure way.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/shadow.html

tar -xf /sources/shadow-*.tar.xz -C /tmp/ \
  && mv /tmp/shadow-* /tmp/shadow \
  && pushd /tmp/shadow

# Disable the installation of the groups program and its man pages,
# as Coreutils provides a better version. Also Prevent the installation
# of manual pages that were already installed by the man pages package:
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

# Instead of using the default crypt method, use yescrypt, which the book
# now prefers over SHA-512 and which libxcrypt provides. It is also
# necessary to change the obsolete
# /var/spool/mail location for user mailboxes that Shadow uses by
# default to the /var/mail location used currently:
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                 \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                \
    -i etc/login.defs

touch /usr/bin/passwd
# --without-libbsd: shadow 4.18 takes readpassphrase() from libbsd, and falls
# back to its own bundled copy only when told libbsd is not wanted. Left to
# search, it fails to find libbsd and then stops rather than falling back.
# --with-{b,yes}crypt needs libxcrypt, built just before this.
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32

# Compile the package:
make

# Install the package:
make exec_prefix=/usr install
if [ $LFS_DOCS -eq 1 ]; then make -C man install-man; fi

# To enable shadowed passwords, run the following command:
pwconv

# To enable shadowed group passwords, run:
grpconv

# Second, to change the default parameters, the file /etc/default/useradd needs to be created and tailored to suit your particular needs. Create it with:
mkdir -p /etc/default
useradd -D --gid 999
sed -i '/MAIL/s/yes/no/' /etc/default/useradd

# Cleanup
popd \
  && rm -rf /tmp/shadow

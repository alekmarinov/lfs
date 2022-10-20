#!/bin/bash
set -e

build="scripts/packages/build-package.sh"

# build lfs packages
$build -p /scripts/packages/lfs/7.5-create-directories.sh
$build -p /scripts/packages/lfs/7.6-create-essentials.sh
$build -p /scripts/packages/lfs/7.7-make-gettext.sh
$build -p /scripts/packages/lfs/7.8-make-bison.sh
$build -p /scripts/packages/lfs/7.9-make-perl.sh
$build -p /scripts/packages/lfs/7.10-make-python.sh
$build -p /scripts/packages/lfs/7.11-make-texinfo.sh
$build -p /scripts/packages/lfs/7.12-make-util-linux.sh
# $build /scripts/packages/lfs/7.13-cleanup.sh
$build -p /scripts/packages/lfs/8.3-make-man-pages.sh
$build -p /scripts/packages/lfs/8.4-make-iana-etc.sh
$build -p /scripts/packages/lfs/8.5-make-glibc.sh
$build -p /scripts/packages/lfs/8.6-make-zlib.sh
$build -p /scripts/packages/lfs/8.7-make-bzip2.sh
$build -p /scripts/packages/lfs/8.8-make-xz.sh
$build -p /scripts/packages/lfs/8.9-make-zstd.sh
$build -p /scripts/packages/lfs/8.10-make-file.sh
$build -p /scripts/packages/lfs/8.11-make-readline.sh
$build -p /scripts/packages/lfs/8.12-make-m4.sh
$build -p /scripts/packages/lfs/8.13-make-bc.sh
$build -p /scripts/packages/lfs/8.14-make-flex.sh
$build -p /scripts/packages/lfs/8.15-make-tcl.sh
$build -p /scripts/packages/lfs/8.16-make-expect.sh
$build -p /scripts/packages/lfs/8.17-make-dejagnu.sh
$build -p /scripts/packages/lfs/8.18-make-binutils.sh
$build -p /scripts/packages/lfs/8.19-make-gmp.sh
$build -p /scripts/packages/lfs/8.20-make-mpfr.sh
$build -p /scripts/packages/lfs/8.21-make-mpc.sh
$build -p /scripts/packages/lfs/8.22-make-attr.sh
$build -p /scripts/packages/lfs/8.23-make-acl.sh
$build -p /scripts/packages/lfs/8.24-make-libcap.sh
$build -p /scripts/packages/lfs/8.25-make-shadow.sh
$build -p /scripts/packages/lfs/8.26-make-gcc.sh
$build -p /scripts/packages/lfs/8.27-make-pkg-config.sh
$build -p /scripts/packages/lfs/8.28-make-ncurses.sh
$build -p /scripts/packages/lfs/8.29-make-sed.sh
$build -p /scripts/packages/lfs/8.30-make-psmisc.sh
$build -p /scripts/packages/lfs/8.31-make-gettext.sh
$build -p /scripts/packages/lfs/8.32-make-bison.sh
$build -p /scripts/packages/lfs/8.33-make-grep.sh
$build -p /scripts/packages/lfs/8.34-make-bash.sh
$build -p /scripts/packages/lfs/8.35-make-libtool.sh
$build -p /scripts/packages/lfs/8.36-make-gdbm.sh
$build -p /scripts/packages/lfs/8.37-make-gperf.sh
$build -p /scripts/packages/lfs/8.38-make-expat.sh
$build -p /scripts/packages/lfs/8.39-make-inetutils.sh
$build -p /scripts/packages/lfs/8.40-make-less.sh
$build -p /scripts/packages/lfs/8.41-make-perl.sh
$build -p /scripts/packages/lfs/8.42-make-xml-parser.sh
$build -p /scripts/packages/lfs/8.43-make-intltool.sh
$build -p /scripts/packages/lfs/8.44-make-autoconf.sh
$build -p /scripts/packages/lfs/8.45-make-automake.sh
$build -p /scripts/packages/lfs/8.46-make-openssl.sh
$build -p /scripts/packages/lfs/8.47-make-kmod.sh
$build -p /scripts/packages/lfs/8.48-make-libelf.sh
$build -p /scripts/packages/lfs/8.49-make-libffi.sh
$build -p /scripts/packages/lfs/8.50-make-python.sh
$build -p /scripts/packages/lfs/8.51-make-wheel.sh
$build -p /scripts/packages/lfs/8.52-make-ninja.sh
$build -p /scripts/packages/lfs/8.53-make-meson.sh
$build -p /scripts/packages/lfs/8.54-make-coreutils.sh
$build -p /scripts/packages/lfs/8.55-make-check.sh
$build -p /scripts/packages/lfs/8.56-make-diffutils.sh
$build -p /scripts/packages/lfs/8.57-make-gawk.sh
$build -p /scripts/packages/lfs/8.58-make-findutils.sh
$build -p /scripts/packages/lfs/8.59-make-groff.sh
$build -p /scripts/packages/lfs/8.60-make-grub.sh
$build -p /scripts/packages/lfs/8.61-make-gzip.sh
$build -p /scripts/packages/lfs/8.62-make-iproute2.sh
$build -p /scripts/packages/lfs/8.63-make-kbd.sh
$build -p /scripts/packages/lfs/8.64-make-libpipeline.sh
$build -p /scripts/packages/lfs/8.65-make-make.sh
$build -p /scripts/packages/lfs/8.66-make-patch.sh
$build -p /scripts/packages/lfs/8.67-make-tar.sh
$build -p /scripts/packages/lfs/8.68-make-texinfo.sh
$build -p /scripts/packages/lfs/8.69-make-vim.sh
$build -p /scripts/packages/lfs/8.70-make-eudev.sh
$build -p /scripts/packages/lfs/8.71-make-man-db.sh
$build -p /scripts/packages/lfs/8.72-make-procps-ng.sh
$build -p /scripts/packages/lfs/8.73-make-util-linux.sh
$build -p /scripts/packages/lfs/8.74-make-e2fsprogs.sh
$build -p /scripts/packages/lfs/8.75-make-sysklogd.sh
$build -p /scripts/packages/lfs/8.76-make-sysvinit.sh
$build /scripts/packages/lfs/8.78-strip.sh 
# # configure system
$build -p /scripts/packages/lfs/9.2-make-lfs-bootscripts.sh
$build -p /scripts/packages/lfs/9.4-managing-devices.sh
$build -p /scripts/packages/lfs/9.5-configure-network.sh
$build -p /scripts/packages/lfs/9.6-configure-systemv.sh
$build -p /scripts/packages/lfs/9.7-configure-bash.sh
$build -p /scripts/packages/lfs/9.8-configure-inputrc.sh
$build -p /scripts/packages/lfs/9.9-configure-shells.sh
$build -p /scripts/packages/lfs/10.2-create-fstab.sh
$build -p /scripts/packages/lfs/10.3-make-linux-kernel.sh
$build -p /scripts/packages/lfs/11.1-the-end.sh

# # build blfs packages
$build -p /scripts/packages/blfs/2-blfs-bootscripts.sh
$build -p /scripts/packages/blfs/5-make-dosfstools.sh
$build -p /scripts/packages/blfs/5-make-mkinitramfs.sh
$build -p /scripts/packages/blfs/12-make-cpio.sh
$build -p /scripts/packages/blfs/9-make-libaio.sh
$build -p /scripts/packages/blfs/5-make-mdadm.sh
$build -p /scripts/packages/blfs/5-make-reiserfsprogs.sh
$build -p /scripts/packages/blfs/13-make-valgrind.sh
$build -p /scripts/packages/blfs/12-make-which.sh
$build -p /scripts/packages/blfs/9-make-inih.sh
$build -p /scripts/packages/blfs/9-make-liburcu.sh
$build -p /scripts/packages/blfs/9-make-icu.sh
$build -p /scripts/packages/blfs/5-make-xfsprogs.sh
$build -p /scripts/packages/blfs/13-make-six.sh
$build -p /scripts/packages/blfs/13-make-gdb.sh
$build -p /scripts/packages/blfs/9-make-libuv.sh
$build -p /scripts/packages/blfs/9-make-libtasn1.sh
$build -p /scripts/packages/blfs/4-make-p11-kit.sh
$build -p /scripts/packages/blfs/9-make-nspr.sh
$build -p /scripts/packages/blfs/22-make-sqlite.sh
$build -p /scripts/packages/blfs/4-make-nss.sh
$build -p /scripts/packages/blfs/12-make-fcron.sh
$build -p /scripts/packages/blfs/4-make-make-ca.sh
$build -p /scripts/packages/blfs/17-make-curl.sh
$build -p /scripts/packages/blfs/9-make-libxml2.sh
$build -p /scripts/packages/blfs/9-make-lzo.sh
$build -p /scripts/packages/blfs/4-make-nettle.sh
$build -p /scripts/packages/blfs/9-make-libarchive.sh
$build -p /scripts/packages/blfs/13-make-cmake.sh
$build -p /scripts/packages/blfs/13-make-llvm.sh
$build -p /scripts/packages/blfs/11-make-sharutils.sh
$build -p /scripts/packages/blfs/17-make-rpcsvc-proto.sh
$build -p /scripts/packages/blfs/17-make-libtirpc.sh
$build -p /scripts/packages/blfs/17-make-libnsl.sh
$build -p /scripts/packages/blfs/22-make-db.sh
$build -p /scripts/packages/blfs/4-make-linux-pam.sh
$build -p /scripts/packages/blfs/4-make-shadow.sh # must rebuild after linux-pam
$build -p /scripts/packages/blfs/48-make-sgml-common.sh
$build -p /scripts/packages/blfs/12-make-unzip.sh
$build -p /scripts/packages/blfs/49-make-docbook-xml.sh
$build -p /scripts/packages/blfs/9-make-libxslt.sh
$build -p /scripts/packages/blfs/9-make-popt.sh
$build -p /scripts/packages/blfs/11-make-mandoc.sh
$build -p /scripts/packages/blfs/5-make-efivar.sh
$build -p /scripts/packages/blfs/5-make-efibootmgr.sh
$build -p /scripts/packages/blfs/13-make-doxygen.sh
$build -p /scripts/packages/blfs/9-make-libgpg-error.sh
$build -p /scripts/packages/blfs/9-make-libassuan.sh
$build -p /scripts/packages/blfs/9-make-libgcrypt.sh
$build -p /scripts/packages/blfs/9-make-libunistring.sh
$build -p /scripts/packages/blfs/4-make-gnutls.sh
$build -p /scripts/packages/blfs/11-make-pinentry.sh
$build -p /scripts/packages/blfs/9-make-npth.sh
$build -p /scripts/packages/blfs/9-make-libksba.sh
$build -p /scripts/packages/blfs/4-make-gnupg.sh
$build -p /scripts/packages/blfs/13-make-git.sh
$build -p /scripts/packages/blfs/10-make-libpng.sh
$build -p /scripts/packages/blfs/10-make-freetype.sh # install without harfbuzz
$build -p /scripts/packages/blfs/10-make-graphite2.sh
$build -p /scripts/packages/blfs/10-make-harfbuzz.sh
$build -p -f /scripts/packages/blfs/10-make-freetype.sh # reinstall with harfbuzz
$build -p /scripts/packages/blfs/5-make-grub.sh

# # clean up
$build /scripts/packages/lfs/8.79-clean.sh

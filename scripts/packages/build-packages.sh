#!/bin/bash
set -e

build="scripts/packages/build-package.sh"

# Clean the package folder before builds start
rm -rf "$LFS_PACKAGE"/*

# mount vkfs to the folder we will chroot
$SCRIPT_DIR/7.3-mount-vkfs.sh > /dev/null 2>&1

# mount overlay to isolate the installed files in $LFS_PACKAGE
mount -t overlay overlay \
    "-olowerdir=$LFS_BASE,upperdir=$LFS_PACKAGE,workdir=overlay/work" \
    "$LFS"

# build lfs packages
$build /scripts/packages/lfs/7.5-create-directories.sh
$build /scripts/packages/lfs/7.6-create-essentials.sh
$build /scripts/packages/lfs/7.7-make-gettext.sh
$build /scripts/packages/lfs/7.8-make-bison.sh
$build /scripts/packages/lfs/7.9-make-perl.sh
$build /scripts/packages/lfs/7.10-make-python.sh
$build /scripts/packages/lfs/7.11-make-texinfo.sh
$build /scripts/packages/lfs/7.12-make-util-linux.sh
# $build /scripts/packages/lfs/7.13-cleanup.sh
$build /scripts/packages/lfs/8.3-make-man-pages.sh
$build /scripts/packages/lfs/8.4-make-iana-etc.sh
$build /scripts/packages/lfs/8.5-make-glibc.sh
$build /scripts/packages/lfs/8.6-make-zlib.sh
$build /scripts/packages/lfs/8.7-make-bzip2.sh
$build /scripts/packages/lfs/8.8-make-xz.sh
$build /scripts/packages/lfs/8.9-make-zstd.sh
$build /scripts/packages/lfs/8.10-make-file.sh
$build /scripts/packages/lfs/8.11-make-readline.sh
$build /scripts/packages/lfs/8.12-make-m4.sh
$build /scripts/packages/lfs/8.13-make-bc.sh
$build /scripts/packages/lfs/8.14-make-flex.sh
$build /scripts/packages/lfs/8.15-make-tcl.sh
$build /scripts/packages/lfs/8.16-make-expect.sh
$build /scripts/packages/lfs/8.17-make-dejagnu.sh
$build /scripts/packages/lfs/8.18-make-binutils.sh
$build /scripts/packages/lfs/8.19-make-gmp.sh
$build /scripts/packages/lfs/8.20-make-mpfr.sh
$build /scripts/packages/lfs/8.21-make-mpc.sh
$build /scripts/packages/lfs/8.22-make-attr.sh
$build /scripts/packages/lfs/8.23-make-acl.sh
$build /scripts/packages/lfs/8.24-make-libcap.sh
$build /scripts/packages/lfs/8.25-make-shadow.sh
$build /scripts/packages/lfs/8.26-make-gcc.sh
$build /scripts/packages/lfs/8.27-make-pkg-config.sh
$build /scripts/packages/lfs/8.28-make-ncurses.sh
$build /scripts/packages/lfs/8.29-make-sed.sh
$build /scripts/packages/lfs/8.30-make-psmisc.sh
$build /scripts/packages/lfs/8.31-make-gettext.sh
$build /scripts/packages/lfs/8.32-make-bison.sh
$build /scripts/packages/lfs/8.33-make-grep.sh
$build /scripts/packages/lfs/8.34-make-bash.sh
$build /scripts/packages/lfs/8.35-make-libtool.sh
$build /scripts/packages/lfs/8.36-make-gdbm.sh
$build /scripts/packages/lfs/8.37-make-gperf.sh
$build /scripts/packages/lfs/8.38-make-expat.sh
$build /scripts/packages/lfs/8.39-make-inetutils.sh
$build /scripts/packages/lfs/8.40-make-less.sh
$build /scripts/packages/lfs/8.41-make-perl.sh
$build /scripts/packages/lfs/8.42-make-xml-parser.sh
$build /scripts/packages/lfs/8.43-make-intltool.sh
$build /scripts/packages/lfs/8.44-make-autoconf.sh
$build /scripts/packages/lfs/8.45-make-automake.sh
$build /scripts/packages/lfs/8.46-make-openssl.sh
$build /scripts/packages/lfs/8.47-make-kmod.sh
$build /scripts/packages/lfs/8.48-make-libelf.sh
$build /scripts/packages/lfs/8.49-make-libffi.sh
$build /scripts/packages/lfs/8.50-make-python.sh
$build /scripts/packages/lfs/8.51-make-wheel.sh
$build /scripts/packages/lfs/8.52-make-ninja.sh
$build /scripts/packages/lfs/8.53-make-meson.sh
$build /scripts/packages/lfs/8.54-make-coreutils.sh
$build /scripts/packages/lfs/8.55-make-check.sh
$build /scripts/packages/lfs/8.56-make-diffutils.sh
$build /scripts/packages/lfs/8.57-make-gawk.sh
$build /scripts/packages/lfs/8.58-make-findutils.sh
$build /scripts/packages/lfs/8.59-make-groff.sh
$build /scripts/packages/lfs/8.60-make-grub.sh
$build /scripts/packages/lfs/8.61-make-gzip.sh
$build /scripts/packages/lfs/8.62-make-iproute2.sh
$build /scripts/packages/lfs/8.63-make-kbd.sh
$build /scripts/packages/lfs/8.64-make-libpipeline.sh
$build /scripts/packages/lfs/8.65-make-make.sh
$build /scripts/packages/lfs/8.66-make-patch.sh
$build /scripts/packages/lfs/8.67-make-tar.sh
$build /scripts/packages/lfs/8.68-make-texinfo.sh
$build /scripts/packages/lfs/8.69-make-vim.sh
$build /scripts/packages/lfs/8.70-make-eudev.sh
$build /scripts/packages/lfs/8.71-make-man-db.sh
$build /scripts/packages/lfs/8.72-make-procps-ng.sh
$build /scripts/packages/lfs/8.73-make-util-linux.sh
$build /scripts/packages/lfs/8.74-make-e2fsprogs.sh
$build /scripts/packages/lfs/8.75-make-sysklogd.sh
$build /scripts/packages/lfs/8.76-make-sysvinit.sh
$build /scripts/packages/lfs/8.78-strip.sh 
# # configure system
$build /scripts/packages/lfs/9.2-make-lfs-bootscripts.sh
$build /scripts/packages/lfs/9.4-managing-devices.sh
$build /scripts/packages/lfs/9.5-configure-network.sh
$build /scripts/packages/lfs/9.6-configure-systemv.sh
$build /scripts/packages/lfs/9.7-configure-bash.sh
$build /scripts/packages/lfs/9.8-configure-inputrc.sh
$build /scripts/packages/lfs/9.9-configure-shells.sh
$build /scripts/packages/lfs/10.2-create-fstab.sh
$build /scripts/packages/lfs/10.3-make-linux-kernel.sh
$build /scripts/packages/lfs/11.1-the-end.sh

# # build blfs packages
$build /scripts/packages/blfs/2-blfs-bootscripts.sh
$build /scripts/packages/blfs/5-make-dosfstools.sh
$build /scripts/packages/blfs/5-make-mkinitramfs.sh
$build /scripts/packages/blfs/12-make-cpio.sh
$build /scripts/packages/blfs/9-make-libaio.sh
$build /scripts/packages/blfs/5-make-mdadm.sh
$build /scripts/packages/blfs/5-make-reiserfsprogs.sh
$build /scripts/packages/blfs/13-make-valgrind.sh
$build /scripts/packages/blfs/12-make-which.sh
$build /scripts/packages/blfs/9-make-inih.sh
$build /scripts/packages/blfs/9-make-liburcu.sh
$build /scripts/packages/blfs/9-make-icu.sh
$build /scripts/packages/blfs/5-make-xfsprogs.sh
$build /scripts/packages/blfs/13-make-six.sh
$build /scripts/packages/blfs/13-make-gdb.sh
$build /scripts/packages/blfs/9-make-libuv.sh
$build /scripts/packages/blfs/9-make-libtasn1.sh
$build /scripts/packages/blfs/4-make-p11-kit.sh
$build /scripts/packages/blfs/9-make-nspr.sh
$build /scripts/packages/blfs/22-make-sqlite.sh
$build /scripts/packages/blfs/4-make-nss.sh
$build /scripts/packages/blfs/12-make-fcron.sh
$build /scripts/packages/blfs/4-make-make-ca.sh
$build /scripts/packages/blfs/17-make-curl.sh
$build /scripts/packages/blfs/9-make-libxml2.sh
$build /scripts/packages/blfs/9-make-lzo.sh
$build /scripts/packages/blfs/4-make-nettle.sh
$build /scripts/packages/blfs/9-make-libarchive.sh
$build /scripts/packages/blfs/13-make-cmake.sh
$build /scripts/packages/blfs/13-make-llvm.sh
$build /scripts/packages/blfs/11-make-sharutils.sh
$build /scripts/packages/blfs/17-make-rpcsvc-proto.sh
$build /scripts/packages/blfs/17-make-libtirpc.sh
$build /scripts/packages/blfs/17-make-libnsl.sh
$build /scripts/packages/blfs/22-make-db.sh
$build /scripts/packages/blfs/4-make-linux-pam.sh
$build /scripts/packages/blfs/4-make-shadow.sh # must rebuild after linux-pam
$build /scripts/packages/blfs/48-make-sgml-common.sh
$build /scripts/packages/blfs/12-make-unzip.sh
$build /scripts/packages/blfs/49-make-docbook-xml.sh
$build /scripts/packages/blfs/9-make-libxslt.sh
$build /scripts/packages/blfs/9-make-popt.sh
$build /scripts/packages/blfs/11-make-mandoc.sh
$build /scripts/packages/blfs/5-make-efivar.sh
$build /scripts/packages/blfs/5-make-efibootmgr.sh
$build /scripts/packages/blfs/13-make-doxygen.sh
$build /scripts/packages/blfs/9-make-libgpg-error.sh
$build /scripts/packages/blfs/9-make-libassuan.sh
$build /scripts/packages/blfs/9-make-libgcrypt.sh
$build /scripts/packages/blfs/9-make-libunistring.sh
$build /scripts/packages/blfs/4-make-gnutls.sh
$build /scripts/packages/blfs/11-make-pinentry.sh
$build /scripts/packages/blfs/9-make-npth.sh
$build /scripts/packages/blfs/9-make-libksba.sh
$build /scripts/packages/blfs/4-make-gnupg.sh
$build /scripts/packages/blfs/13-make-git.sh
$build /scripts/packages/blfs/10-make-libpng.sh
$build /scripts/packages/blfs/10-make-freetype.sh # install without harfbuzz
$build /scripts/packages/blfs/10-make-graphite2.sh
$build /scripts/packages/blfs/10-make-harfbuzz.sh
$build -f /scripts/packages/blfs/10-make-freetype.sh # reinstall with harfbuzz
$build /scripts/packages/blfs/5-make-grub.sh

# clean up
$build /scripts/packages/lfs/8.79-clean.sh

sync
umount $LFS
$SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1

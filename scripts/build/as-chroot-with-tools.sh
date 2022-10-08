#!/bin/bash
set -e
echo "Continue with chroot environment.."

# SKIP remove the "I have no name!" prompt
# exec /tools/bin/bash --login +h

# build toolchain
sh /tools/7.5-create-directories.sh
sh /tools/7.6-create-essentials.sh
sh /tools/7.7-make-gettext.sh
sh /tools/7.8-make-bison.sh
sh /tools/7.9-make-perl.sh
sh /tools/7.10-make-python.sh
sh /tools/7.11-make-texinfo.sh
sh /tools/7.12-make-util-linux.sh
sh /tools/7.13-cleanup.sh
sh /tools/8.3-make-man-pages.sh
sh /tools/8.4-make-iana-etc.sh
sh /tools/8.5-make-glibc.sh
sh /tools/8.6-make-zlib.sh
sh /tools/8.7-make-bzip2.sh
sh /tools/8.8-make-xz.sh
sh /tools/8.9-make-zstd.sh
sh /tools/8.10-make-file.sh
sh /tools/8.11-make-readline.sh
sh /tools/8.12-make-m4.sh
sh /tools/8.13-make-bc.sh
sh /tools/8.14-make-flex.sh
sh /tools/8.15-make-tcl.sh
sh /tools/8.16-make-expect.sh
sh /tools/8.17-make-dejagnu.sh
sh /tools/8.18-make-binutils.sh
sh /tools/8.19-make-gmp.sh
sh /tools/8.20-make-mpfr.sh
sh /tools/8.21-make-mpc.sh
sh /tools/8.22-make-attr.sh
sh /tools/8.23-make-acl.sh
sh /tools/8.24-make-libcap.sh
sh /tools/8.25-make-shadow.sh
sh /tools/8.26-make-gcc.sh
sh /tools/8.27-make-pkg-config.sh
sh /tools/8.28-make-ncurses.sh
sh /tools/8.29-make-sed.sh
sh /tools/8.30-make-psmisc.sh
sh /tools/8.31-make-gettext.sh
sh /tools/8.32-make-bison.sh
sh /tools/8.33-make-grep.sh
sh /tools/8.34-make-bash.sh
sh /tools/8.35-make-libtool.sh
sh /tools/8.36-make-gdbm.sh
sh /tools/8.37-make-gperf.sh
sh /tools/8.38-make-expat.sh
sh /tools/8.39-make-inetutils.sh
sh /tools/8.40-make-less.sh
sh /tools/8.41-make-perl.sh
sh /tools/8.42-make-xml-parser.sh
sh /tools/8.43-make-intltool.sh
sh /tools/8.44-make-autoconf.sh
sh /tools/8.45-make-automake.sh
sh /tools/8.46-make-openssl.sh
sh /tools/8.47-make-kmod.sh
sh /tools/8.48-make-libelf.sh
sh /tools/8.49-make-libffi.sh
sh /tools/8.50-make-python.sh
sh /tools/8.51-make-wheel.sh
sh /tools/8.52-make-ninja.sh
sh /tools/8.53-make-meson.sh
sh /tools/8.54-make-coreutils.sh
sh /tools/8.55-make-check.sh
sh /tools/8.56-make-diffutils.sh
sh /tools/8.57-make-gawk.sh
sh /tools/8.58-make-findutils.sh
sh /tools/8.59-make-groff.sh
sh /tools/8.60-make-grub.sh
sh /tools/8.61-make-gzip.sh
sh /tools/8.62-make-iproute2.sh
sh /tools/8.63-make-kbd.sh
sh /tools/8.64-make-libpipeline.sh
sh /tools/8.65-make-make.sh
sh /tools/8.66-make-patch.sh
sh /tools/8.67-make-tar.sh
sh /tools/8.68-make-texinfo.sh
sh /tools/8.69-make-vim.sh
sh /tools/8.70-make-eudev.sh
sh /tools/8.71-make-man-db.sh
sh /tools/8.72-make-procps-ng.sh
sh /tools/8.73-make-util-linux.sh
sh /tools/8.74-make-e2fsprogs.sh
sh /tools/8.75-make-sysklogd.sh
sh /tools/8.76-make-sysvinit.sh
sh /tools/8.78-strip.sh
sh /tools/8.79-clean.sh

exit

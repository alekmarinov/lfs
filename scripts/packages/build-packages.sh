#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
__NAME__=$(basename "$0")

for var in LFS LFS_BASE LFS_PACKAGE; do
    if [ "${!var}" == "" ]; then
        echo "$__NAME__: $var is not defined"
        exit 1
    fi
done

# Clean the package folder before builds start
rm -rf "$LFS_PACKAGE"/*

# build lfs packages
build="scripts/packages/build-package.sh"

# build lfs packages
$build /scripts/packages/lfs/7.5-create-directories.sh
$build /scripts/packages/lfs/7.6-create-essentials.sh
$build /scripts/packages/lfs/7.7-make-gettext.sh
$build /scripts/packages/lfs/7.8-make-bison.sh
$build /scripts/packages/lfs/7.9-make-perl.sh
$build /scripts/packages/lfs/7.10-make-python.sh
$build /scripts/packages/lfs/7.11-make-texinfo.sh
$build /scripts/packages/lfs/7.12-make-util-linux.sh
$build /scripts/packages/lfs/7.13-cleanup.sh
$build /scripts/packages/lfs/8.3-make-man-pages.sh
$build /scripts/packages/lfs/8.4-make-iana-etc.sh
$build /scripts/packages/lfs/8.5-make-glibc.sh
$build /scripts/packages/lfs/8.6-make-zlib.sh
$build /scripts/packages/lfs/8.7-make-bzip2.sh
$build /scripts/packages/lfs/8.8-make-xz.sh
$build /scripts/packages/lfs/8.9-make-lz4.sh
$build /scripts/packages/lfs/8.10-make-zstd.sh
$build /scripts/packages/lfs/8.11-make-file.sh
$build /scripts/packages/lfs/8.12-make-readline.sh
$build /scripts/packages/lfs/8.13-make-m4.sh
$build /scripts/packages/lfs/8.14-make-bc.sh
$build /scripts/packages/lfs/8.15-make-flex.sh
$build /scripts/packages/lfs/8.16-make-tcl.sh
$build /scripts/packages/lfs/8.17-make-expect.sh
$build /scripts/packages/lfs/8.18-make-dejagnu.sh
$build /scripts/packages/lfs/8.19-make-pkgconf.sh
$build /scripts/packages/lfs/8.20-make-binutils.sh
$build /scripts/packages/lfs/8.21-make-gmp.sh
$build /scripts/packages/lfs/8.22-make-mpfr.sh
$build /scripts/packages/lfs/8.23-make-mpc.sh
$build /scripts/packages/lfs/8.24-make-attr.sh
$build /scripts/packages/lfs/8.25-make-acl.sh
$build /scripts/packages/lfs/8.26-make-libcap.sh
$build /scripts/packages/lfs/8.27-make-libxcrypt.sh
$build /scripts/packages/lfs/8.28-make-shadow.sh
$build /scripts/packages/lfs/8.29-make-gcc.sh
$build /scripts/packages/lfs/8.30-make-ncurses.sh
$build /scripts/packages/lfs/8.31-make-sed.sh
$build /scripts/packages/lfs/8.32-make-psmisc.sh
$build /scripts/packages/lfs/8.33-make-gettext.sh
$build /scripts/packages/lfs/8.34-make-bison.sh
$build /scripts/packages/lfs/8.35-make-grep.sh
$build /scripts/packages/lfs/8.36-make-bash.sh
$build /scripts/packages/lfs/8.37-make-libtool.sh
$build /scripts/packages/lfs/8.38-make-gdbm.sh
$build /scripts/packages/lfs/8.39-make-gperf.sh
$build /scripts/packages/lfs/8.40-make-expat.sh
$build /scripts/packages/lfs/8.41-make-inetutils.sh
$build /scripts/packages/lfs/8.42-make-less.sh
$build /scripts/packages/lfs/8.43-make-perl.sh
$build /scripts/packages/lfs/8.44-make-xml-parser.sh
$build /scripts/packages/lfs/8.45-make-intltool.sh
$build /scripts/packages/lfs/8.46-make-autoconf.sh
$build /scripts/packages/lfs/8.47-make-automake.sh
$build /scripts/packages/lfs/8.48-make-openssl.sh
$build /scripts/packages/lfs/8.49-make-libelf.sh
$build /scripts/packages/lfs/8.50-make-libffi.sh
$build /scripts/packages/lfs/8.51-make-python.sh
$build /scripts/packages/lfs/8.52-make-flit-core.sh
$build /scripts/packages/lfs/8.53-make-packaging.sh
$build /scripts/packages/lfs/8.54-make-wheel.sh
$build /scripts/packages/lfs/8.55-make-setuptools.sh
$build /scripts/packages/lfs/8.56-make-ninja.sh
$build /scripts/packages/lfs/8.57-make-meson.sh
$build /scripts/packages/lfs/8.58-make-kmod.sh
$build /scripts/packages/lfs/8.59-make-coreutils.sh
$build /scripts/packages/lfs/8.60-make-diffutils.sh
$build /scripts/packages/lfs/8.61-make-gawk.sh
$build /scripts/packages/lfs/8.62-make-findutils.sh
$build /scripts/packages/lfs/8.63-make-groff.sh
$build /scripts/packages/lfs/8.64-make-grub.sh
$build /scripts/packages/lfs/8.65-make-gzip.sh
$build /scripts/packages/lfs/8.66-make-iproute2.sh
$build /scripts/packages/lfs/8.67-make-kbd.sh
$build /scripts/packages/lfs/8.68-make-libpipeline.sh
$build /scripts/packages/lfs/8.69-make-make.sh
$build /scripts/packages/lfs/8.70-make-patch.sh
$build /scripts/packages/lfs/8.71-make-tar.sh
$build /scripts/packages/lfs/8.72-make-texinfo.sh
$build /scripts/packages/lfs/8.73-make-vim.sh
$build /scripts/packages/lfs/8.74-make-markupsafe.sh
$build /scripts/packages/lfs/8.75-make-jinja2.sh
$build /scripts/packages/lfs/8.76-make-udev.sh
$build /scripts/packages/lfs/8.77-make-man-db.sh
$build /scripts/packages/lfs/8.78-make-procps-ng.sh
$build /scripts/packages/lfs/8.79-make-util-linux.sh
$build /scripts/packages/lfs/8.80-make-e2fsprogs.sh
$build /scripts/packages/lfs/8.81-make-sysklogd.sh
$build /scripts/packages/lfs/8.82-make-sysvinit.sh
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

# build blfs packages
$build /scripts/packages/blfs/2-blfs-bootscripts.sh
$build /scripts/packages/blfs/5-make-dosfstools.sh
$build /scripts/packages/blfs/5-make-mkinitramfs.sh
$build /scripts/packages/blfs/12-make-cpio.sh
$build /scripts/packages/blfs/3-make-microcode.sh # needs cpio
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
$build /scripts/packages/blfs/9-make-libusb.sh
$build /scripts/packages/blfs/9-make-libevdev.sh
$build /scripts/packages/blfs/9-make-mtdev.sh
$build /scripts/packages/blfs/9-make-libinput.sh
$build /scripts/packages/blfs/9-make-libtasn1.sh
$build /scripts/packages/blfs/4-make-p11-kit.sh
$build /scripts/packages/blfs/9-make-nspr.sh
$build /scripts/packages/blfs/22-make-sqlite.sh
# Rebuild python now that sqlite is there, or it has no _sqlite3
# module. -f is needed because python was already built and would
# otherwise be skipped; the marker stops a resumed run from paying
# for this long build again.
if [ ! -f tmp/8.51-make-python.rebuilt ]; then
    $build -f /scripts/packages/lfs/8.51-make-python.sh
    touch tmp/8.51-make-python.rebuilt
fi
$build /scripts/packages/blfs/4-make-nss.sh
$build /scripts/packages/blfs/12-make-fcron.sh
$build /scripts/packages/blfs/4-make-make-ca.sh
$build /scripts/packages/blfs/x-make-ca-certificates.sh
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
$build /scripts/packages/blfs/4-make-openssh.sh
$build /scripts/packages/blfs/4-make-sudo.sh
$build /scripts/packages/blfs/12-make-pciutils.sh
$build /scripts/packages/blfs/12-make-usbutils.sh
$build /scripts/packages/blfs/12-make-dbus.sh
$build /scripts/packages/blfs/12-make-acpid.sh
$build /scripts/packages/blfs/14-make-dhcpcd.sh

# wireless. libnl first, both iw and wpa_supplicant link against it.
$build /scripts/packages/blfs/17-make-libnl.sh
$build /scripts/packages/blfs/15-make-iw.sh
$build /scripts/packages/blfs/x-make-wireless-regdb.sh
$build /scripts/packages/blfs/x-make-linux-firmware-iwlwifi.sh
$build /scripts/packages/blfs/x-make-linux-firmware-realtek.sh
$build /scripts/packages/blfs/15-make-wpa-supplicant.sh
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
$build /scripts/packages/blfs/10-make-fontconfig.sh
$build /scripts/packages/blfs/10-make-pixman.sh

# Xorg build environment and libraries
$build /scripts/packages/blfs/24-make-util-macros.sh
$build /scripts/packages/blfs/24-make-xorgproto.sh
$build /scripts/packages/blfs/24-make-libXau.sh
$build /scripts/packages/blfs/24-make-libXdmcp.sh
$build /scripts/packages/blfs/24-make-xcb-proto.sh
$build /scripts/packages/blfs/24-make-libxcb.sh
$build /scripts/packages/blfs/24-make-xorg-libraries.sh
$build /scripts/packages/blfs/24-make-libdrm.sh
$build /scripts/packages/blfs/24-make-libxcvt.sh
$build /scripts/packages/blfs/24-make-xbitmaps.sh
$build /scripts/packages/blfs/24-make-xorg-apps.sh
$build /scripts/packages/blfs/24-make-xcursor-themes.sh
$build /scripts/packages/blfs/24-make-xorg-fonts.sh
$build /scripts/packages/blfs/24-make-xkeyboard-config.sh
# OpenGL. Mako generates part of Mesa's source, Mesa is what xorg-server needs
# before glamor, dri and glx can be turned on.
$build /scripts/packages/blfs/x-make-mako.sh
# The gtk3 chain, which is what a browser needs. nasm is only an assembler for
# libjpeg-turbo's SIMD code and for Firefox later.
$build /scripts/packages/blfs/13-make-nasm.sh
$build /scripts/packages/blfs/9-make-pcre.sh
$build /scripts/packages/blfs/9-make-glib.sh
$build /scripts/packages/blfs/10-make-fribidi.sh
$build /scripts/packages/blfs/11-make-shared-mime-info.sh
$build /scripts/packages/blfs/10-make-libjpeg-turbo.sh
$build /scripts/packages/blfs/10-make-libtiff.sh
$build /scripts/packages/blfs/25-make-gdk-pixbuf.sh
$build /scripts/packages/blfs/25-make-atk.sh
$build /scripts/packages/blfs/25-make-at-spi2-core.sh
$build /scripts/packages/blfs/25-make-at-spi2-atk.sh
$build /scripts/packages/blfs/24-make-mesa.sh
$build /scripts/packages/blfs/25-make-libepoxy.sh
$build /scripts/packages/blfs/25-make-glu.sh
$build /scripts/packages/blfs/24-make-mesa-demos.sh
$build /scripts/packages/blfs/25-make-cairo.sh
$build /scripts/packages/blfs/25-make-pango.sh
$build /scripts/packages/blfs/25-make-gtk3.sh

# the firefox tier. rust is a build tool and is in no distro.
$build /scripts/packages/blfs/12-make-zip.sh
$build /scripts/packages/blfs/42-make-alsa-lib.sh
$build /scripts/packages/blfs/42-make-alsa-utils.sh
$build /scripts/packages/blfs/13-make-rust.sh
$build /scripts/packages/blfs/9-make-nodejs.sh
$build /scripts/packages/blfs/13-make-cbindgen.sh
$build /scripts/packages/blfs/9-make-dbus-glib.sh
$build /scripts/packages/blfs/x-make-python310.sh # firefox needs a pre-3.12 python
$build /scripts/packages/blfs/40-make-firefox.sh
$build /scripts/packages/blfs/24-make-xorg-server.sh
$build /scripts/packages/blfs/24-make-xf86-input-libinput.sh
$build /scripts/packages/blfs/24-make-xinit.sh
$build /scripts/packages/blfs/24-make-twm.sh
$build /scripts/packages/blfs/24-make-xclock.sh
$build /scripts/packages/blfs/24-make-xterm.sh
$build /scripts/packages/blfs/24-make-dejavu-fonts.sh
$build /scripts/packages/blfs/27-make-fluxbox.sh
$build /scripts/packages/blfs/5-make-grub.sh

# clean up
$build /scripts/packages/lfs/8.85-clean.sh

# FIXME: Stripping must be done without overlay
# That can become separate make target
# $build /scripts/packages/lfs/8.84-strip.sh 

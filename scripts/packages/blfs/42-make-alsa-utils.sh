#!/bin/bash
set -e
echo "Building BLFS-alsa-utils.."
echo "Approximate build time: less than 0.2 SBU"
echo "Required disk space: 30 MB"

# 42. alsa-utils
# alsactl and amixer. alsa-lib is the library programs link against; this is the
# userspace that puts the mixer into a usable state.
#
# It is not optional for a machine meant to make a sound. ALSA mixers come up
# muted on most codecs, and nothing else in this build unmutes them - so without
# alsactl the hardware works, the driver works, the application opens the device
# happily, and the speakers stay silent with nothing reporting an error.
#
# https://www.linuxfromscratch.org/blfs/view/11.2/multimedia/alsa-utils.html
#
# BUILD_REQUIRES: 42-make-alsa-lib 8.30-make-ncurses
# RUNTIME_REQUIRES: 42-make-alsa-lib 8.30-make-ncurses
#
# NOTE the sed on init_sysdeps.c. alsa-utils carries its own strlcpy and
# strlcat behind a guard that reads 'if this is glibc, define them ourselves' -
# true when it was written, and wrong since glibc 2.38 added both. The static
# definitions then collide with the real ones. The guard is made version aware
# rather than the functions deleted, so it still builds against an older glibc.
#
# NOTE --disable-alsaconf and --disable-xmlto. alsaconf is an interactive
# ncurses script for machines that need their card configured by hand, which is
# not this one, and xmlto is a documentation toolchain we do not build.

VER=$(ls /sources/alsa-utils-*.tar.bz2 | sed 's/^[^0-9]*//; s/\.tar\.bz2$//')

rm -rf /tmp/alsa-utils
tar -xf /sources/alsa-utils-*.tar.bz2 -C /tmp/ \
    && mv /tmp/alsa-utils-* /tmp/alsa-utils \
    && pushd /tmp/alsa-utils \
    && sed -i 's|^#if defined(__GLIBC__) && !(defined(__UCLIBC__) && defined(__USE_BSD))$|#if defined(__GLIBC__) \&\& !(defined(__UCLIBC__) \&\& defined(__USE_BSD)) \&\& !__GLIBC_PREREQ(2,38)|' \
        alsactl/init_sysdeps.c \
    && ./configure \
        --prefix=/usr \
        --sbindir=/usr/sbin \
        --disable-alsaconf \
        --disable-bat \
        --disable-xmlto \
        --with-curses=ncursesw \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/alsa-utils \
    || exit 1

# The two the boot script calls. Without them the distro is silent and says
# nothing about why.
test -x /usr/sbin/alsactl
test -x /usr/bin/amixer
echo "alsa-utils $VER installed"

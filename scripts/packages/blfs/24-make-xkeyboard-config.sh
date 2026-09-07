#!/bin/bash
# PACKAGE:  xkeyboard-config
# SOURCE:   xkeyboard-config-*.tar.xz
# RELEASE:  1
# GROUP:    xorg
# CLASS:    extra
set -e
echo "Building BLFS-xkeyboard-config.."

# 24. xkeyboard-config
# The keyboard layouts the Xorg server compiles with xkbcomp.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xkeyboard-config.html

. /etc/profile.d/xorg.sh

# NOTE three legacy paths are removed before installing.
#
# 2.45 versions its database as xkeyboard-config-2 and leaves the old names
# behind as symlinks. meson refuses to replace a regular file or a directory
# with a symlink -
#   ERROR: Destination '...' already exists and is not a symlink
# - and 2.36 put real ones there, which are still in the build base because
# the base is cumulative. The three it turns into symlinks are the pkgconfig
# file, the unversioned man page, and /usr/share/X11/xkb, which was the whole
# keyboard database directory and is now a link to the versioned one. The
# other 45 xkeyboard-config files in the base are .mo catalogues, which stay
# regular files and are simply overwritten.
#
# Removed here rather than by hand so the deletion goes through the overlay as
# a whiteout: it lands in the package's .meta/removed, and an installed system
# drops the old paths when it upgrades instead of keeping a stale directory
# shadowing the new symlink.
rm -rf /tmp/xkeyboard-config
tar -xf /sources/xkeyboard-config-*.tar.xz -C /tmp/ \
    && mv /tmp/xkeyboard-config-* /tmp/xkeyboard-config \
    && pushd /tmp/xkeyboard-config \
    && mkdir build && pushd build \
    && meson setup --prefix=$XORG_PREFIX --buildtype=release .. \
    && ninja \
    && rm -f  $XORG_PREFIX/share/pkgconfig/xkeyboard-config.pc \
    && rm -f  $XORG_PREFIX/share/man/man7/xkeyboard-config.7 \
    && rm -rf $XORG_PREFIX/share/X11/xkb \
    && ninja install \
    && popd && popd \
    && rm -rf /tmp/xkeyboard-config \
    || exit 1

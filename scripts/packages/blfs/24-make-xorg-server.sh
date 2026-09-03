#!/bin/bash
# PACKAGE:  xorg-server
# SOURCE:   xorg-server-*.tar.xz
# RELEASE:  1
# GROUP:    xorg
# CLASS:    extra
set -e
echo "Building BLFS-Xorg Server.."
echo "Approximate build time: 1.5 SBU"
echo "Required disk space: 340 MB"

# 24. Xorg Server
#
# The X server itself. It was first built without Mesa and libepoxy, which the
# book only recommends: DRI and GLX were off and the modesetting driver fell
# back to the shadow frame buffer, rendering on the CPU. That was enough to
# bring a session up and it kept the whole GL stack out of the build.
#
# Now that Mesa and libepoxy exist they are turned on. glamor is the
# acceleration path and needs libepoxy; GLX is what makes the server able to
# answer a client asking for OpenGL at all, which every real toolkit does.
#
# required: libxcvt, pixman, font-util, xkeyboard-config
# recommended, and now present: mesa, libepoxy
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xorg-server.html
#
# NOTE -Wno-error=array-bounds. GCC 15 traces the strncpy in Xorg's own
# Xtrans.c far enough to see it copying past the end of utsname.nodename, and
# xorg-server compiles with -Werror. The call is bounded by the destination
# size, so the truncation it warns about is what the code intends.
#
# BUILD_REQUIRES: 24-make-mesa 25-make-libepoxy 24-make-libxcvt 10-make-pixman 24-make-xkeyboard-config 24-make-xorg-libraries 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES: 24-make-xkeyboard-config 24-make-xorg-fonts
#
# Neither is linked by anything Xorg ships, and Xorg cannot start without
# either. Without the XKB rule files it aborts with "Failed to activate
# virtual core keyboard"; that is not a warning, the server exits. Found by
# installing the X server on a machine that had neither and watching it die.
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/xorg-server
tar -xf /sources/xorg-server-*.tar.xz -C /tmp/
mv /tmp/xorg-server-* /tmp/xorg-server
pushd /tmp/xorg-server

mkdir build
pushd build
meson --prefix=$XORG_PREFIX \
      --localstatedir=/var \
      -Dsuid_wrapper=true \
      -Dxkb_output_dir=/var/lib/xkb \
      -Dglamor=true \
      -Ddri1=false \
      -Ddri2=true \
      -Ddri3=true \
      -Dglx=true \
      -Dc_args="-Wno-error=array-bounds" \
      ..
ninja
ninja install
popd
popd
rm -rf /tmp/xorg-server

mkdir -pv /etc/X11/xorg.conf.d

# the sockets the server and the session manager bind, recreated on every boot
cat >> /etc/sysconfig/createfiles << "EOF"
/tmp/.ICE-unix dir 1777 root root
/tmp/.X11-unix dir 1777 root root
EOF

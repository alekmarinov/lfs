#!/bin/bash
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
# BUILD_REQUIRES: 24-make-mesa 24-make-libepoxy 24-make-libxcvt 10-make-pixman 24-make-xkeyboard-config 24-make-xorg-libraries 8.53-make-meson 8.52-make-ninja
# RUNTIME_REQUIRES:
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

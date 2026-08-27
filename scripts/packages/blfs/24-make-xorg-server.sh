#!/bin/bash
set -e
echo "Building BLFS-Xorg Server.."
echo "Approximate build time: 1.5 SBU"
echo "Required disk space: 340 MB"

# 24. Xorg Server
#
# The X server itself. Mesa and libepoxy are only recommended by the book, not
# required, so the server is built without them: DRI and GLX are the parts
# which need them and are turned off, and the modesetting driver falls back to
# the shadow frame buffer. Rendering is then done on the CPU, which is enough
# to bring a session up. Turning these back on is what installing Mesa buys.
#
# required: libxcvt, pixman, font-util, xkeyboard-config
# https://www.linuxfromscratch.org/blfs/view/11.2/x/xorg-server.html
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
      -Dglamor=false \
      -Ddri1=false \
      -Ddri2=false \
      -Ddri3=false \
      -Dglx=false \
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

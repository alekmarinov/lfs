#!/bin/bash
set -e
echo "Building BLFS-util-macros.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 5.5 MB"

# 24. util-macros
# The util-macros package contains the m4 macros every Xorg package uses to
# configure itself. It is the first package of the Xorg build.
# https://www.linuxfromscratch.org/blfs/view/11.2/x/util-macros.html

# The whole Xorg build is parameterised by these two, exported here for the
# packages which follow and installed for the built system.
export XORG_PREFIX="/usr"
export XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"

install -v -dm755 /etc/profile.d
cat > /etc/profile.d/xorg.sh << "EOF2"
XORG_PREFIX="/usr"
XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
export XORG_PREFIX XORG_CONFIG
EOF2
chmod 644 /etc/profile.d/xorg.sh

tar -xf /sources/util-macros-*.tar.bz2 -C /tmp/ \
    && mv /tmp/util-macros-* /tmp/util-macros \
    && pushd /tmp/util-macros \
    && ./configure $XORG_CONFIG \
    && make install \
    && popd \
    && rm -rf /tmp/util-macros \
    || exit 1

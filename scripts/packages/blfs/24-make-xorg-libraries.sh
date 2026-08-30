#!/bin/bash
set -e
echo "Building BLFS-Xorg libraries.."
echo "Approximate build time: 3.5 SBU"
echo "Required disk space: 240 MB"

# 24. Xorg Libraries
#
# The book builds these as one page rather than one package each, because they
# are one release series which has to be installed in this order. The order is
# the order of the lib-7.md5 file of the book and must not be sorted.
#
# required: fontconfig, libxcb
# https://www.linuxfromscratch.org/blfs/view/11.2/x/x7lib.html

. /etc/profile.d/xorg.sh

PACKAGES="
xtrans-1.4.0.tar.bz2
libX11-1.8.1.tar.xz
libXext-1.3.4.tar.bz2
libFS-1.0.8.tar.bz2
libICE-1.0.10.tar.bz2
libSM-1.2.3.tar.bz2
libXScrnSaver-1.2.3.tar.bz2
libXt-1.2.1.tar.bz2
libXmu-1.1.3.tar.bz2
libXpm-3.5.13.tar.bz2
libXaw-1.0.14.tar.bz2
libXfixes-6.0.0.tar.bz2
libXcomposite-0.4.5.tar.bz2
libXrender-0.9.10.tar.bz2
libXcursor-1.2.1.tar.xz
libXdamage-1.1.5.tar.bz2
libfontenc-1.1.4.tar.bz2
libXfont2-2.0.5.tar.bz2
libXft-2.3.4.tar.bz2
libXi-1.8.tar.bz2
libXinerama-1.1.4.tar.bz2
libXrandr-1.5.2.tar.bz2
libXres-1.2.1.tar.bz2
libXtst-1.2.3.tar.bz2
libXv-1.0.11.tar.bz2
libXvMC-1.0.13.tar.xz
libXxf86dga-1.1.5.tar.bz2
libXxf86vm-1.1.4.tar.bz2
libdmx-1.1.4.tar.bz2
libpciaccess-0.16.tar.bz2
libxkbfile-1.1.0.tar.bz2
libxshmfence-1.3.tar.bz2
"

pushd /tmp
# The X libraries are old C: libXt names a variable 'true' and others use the
# empty parameter list to mean 'unspecified'. Both changed meaning in C23, which
# GCC 15 defaults to, so the whole set is built against the standard it was
# written for rather than patching each library in turn.
export CC='gcc -std=gnu17'

for package in $PACKAGES; do
    packagedir=${package%.tar.?z*}
    echo "=== $packagedir ==="
    rm -rf "/tmp/$packagedir"
    tar -xf "/sources/$package" -C /tmp/
    pushd "/tmp/$packagedir"

    docdir="--docdir=$XORG_PREFIX/share/doc/$packagedir"
    case $packagedir in
        libXfont2-[0-9]* )
            ./configure $XORG_CONFIG $docdir --disable-devel-docs
        ;;
        libXt-[0-9]* )
            ./configure $XORG_CONFIG $docdir \
                        --with-appdefaultdir=/etc/X11/app-defaults
        ;;
        libX11-* )
            ./configure $XORG_CONFIG --disable-thread-safety-constructor
        ;;
        * )
            ./configure $XORG_CONFIG $docdir
        ;;
    esac

    make
    make install
    popd
    rm -rf "/tmp/$packagedir"
    /sbin/ldconfig
done
popd

echo "Installed $(echo $PACKAGES | wc -w) Xorg libraries"

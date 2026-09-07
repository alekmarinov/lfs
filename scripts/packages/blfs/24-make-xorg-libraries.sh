#!/bin/bash
# PACKAGE:  xorg-libraries
# VERSION:  11.2
# RELEASE:  1
# CLASS:    extra
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
# https://www.linuxfromscratch.org/blfs/view/12.4/x/x7lib.html

. /etc/profile.d/xorg.sh

PACKAGES="
xtrans-1.6.0.tar.xz
libX11-1.8.12.tar.xz
libXext-1.3.6.tar.xz
libFS-1.0.10.tar.xz
libICE-1.1.2.tar.xz
libSM-1.2.6.tar.xz
libXScrnSaver-1.2.4.tar.xz
libXt-1.3.1.tar.xz
libXmu-1.2.1.tar.xz
libXpm-3.5.17.tar.xz
libXaw-1.0.16.tar.xz
libXfixes-6.0.1.tar.xz
libXcomposite-0.4.6.tar.xz
libXrender-0.9.12.tar.xz
libXcursor-1.2.3.tar.xz
libXdamage-1.1.6.tar.xz
libfontenc-1.1.8.tar.xz
libXfont2-2.0.7.tar.xz
libXft-2.3.9.tar.xz
libXi-1.8.2.tar.xz
libXinerama-1.1.5.tar.xz
libXrandr-1.5.4.tar.xz
libXres-1.2.2.tar.xz
libXtst-1.2.5.tar.xz
libXv-1.0.13.tar.xz
libXvMC-1.0.14.tar.xz
libXxf86dga-1.1.6.tar.xz
libXxf86vm-1.1.6.tar.xz
libpciaccess-0.18.1.tar.xz
libxkbfile-1.1.3.tar.xz
libxshmfence-1.3.3.tar.xz
libXpresent-1.0.1.tar.xz
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
        # libpciaccess dropped autotools at 0.18: there is no configure in the
        # tarball at all, so the default branch below fails with
        # './configure: No such file or directory'. It is the only one of the
        # 32 which has moved; the rest are still autotools, and the apps and
        # fonts lists have none.
        libpciaccess-[0-9]* )
            mkdir build
            cd build
            meson setup --prefix=$XORG_PREFIX --buildtype=release ..
            ninja
            ninja install
            popd
            rm -rf "/tmp/$packagedir"
            /sbin/ldconfig
            continue
        ;;
        libXfont2-[0-9]* )
            ./configure $XORG_CONFIG $docdir --disable-devel-docs
        ;;
        # the book carries this; without it libXpm reads compressed pixmaps by
        # shelling out, which makes gzip a runtime dependency of anything
        # drawing an XPM
        libXpm-[0-9]* )
            ./configure $XORG_CONFIG $docdir --disable-open-zfile
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

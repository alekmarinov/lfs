#!/bin/bash
# PACKAGE:  tcl
# SOURCE:   tcl*-src.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building Tcl.."
echo "Approximate build time: 3.2 SBU"
echo "Required disk space: 88 MB"

# 8.15. Tcl
# The Tcl package contains the Tool Command Language, a robust general-purpose
# scripting language. The Expect package is written in the Tcl language.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/tcl.html
#
# NOTE the bundled tdbc and itcl versions are read from the tree rather than
# written out. They move with every Tcl release - 1.1.3/4.2.2 in 11.2,
# 1.1.10/4.3.2 in 12.4 - and a stale one makes sed fail on a missing file.

VER=$(ls /sources/tcl*-src.tar.gz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/tcl*-src.tar.gz -C /tmp/ \
    && mv /tmp/tcl* /tmp/tcl \
    && pushd /tmp/tcl \
    && tar -xf /sources/tcl*-html.tar.gz --strip-components=1 \
    && SRCDIR=$(pwd) \
    && cd unix \
    && ./configure \
        --prefix=/usr \
        --mandir=/usr/share/man \
    && make \
    && sed -e "s|$SRCDIR/unix|/usr/lib|" \
        -e "s|$SRCDIR|/usr/include|" \
        -i tclConfig.sh \
    && TDBC=$(basename $(ls -d $SRCDIR/pkgs/tdbc1*/ | head -1)) \
    && ITCL=$(basename $(ls -d $SRCDIR/pkgs/itcl4*/ | head -1)) \
    && sed -e "s|$SRCDIR/unix/pkgs/$TDBC|/usr/lib/$TDBC|" \
        -e "s|$SRCDIR/pkgs/$TDBC/generic|/usr/include|" \
        -e "s|$SRCDIR/pkgs/$TDBC/library|/usr/lib/tcl8.6|" \
        -e "s|$SRCDIR/pkgs/$TDBC|/usr/include|" \
        -i pkgs/$TDBC/tdbcConfig.sh \
    && sed -e "s|$SRCDIR/unix/pkgs/$ITCL|/usr/lib/$ITCL|" \
        -e "s|$SRCDIR/pkgs/$ITCL/generic|/usr/include|" \
        -e "s|$SRCDIR/pkgs/$ITCL|/usr/include|" \
        -i pkgs/$ITCL/itclConfig.sh \
    && unset SRCDIR \
    && if [ $LFS_TEST -eq 1 ]; then make test; fi \
    && make install \
    && chmod -v u+w /usr/lib/libtcl*.so \
    && make install-private-headers \
    && ln -sfv tclsh8.6 /usr/bin/tclsh \
    && mv /usr/share/man/man3/{Thread,Tcl_Thread}.3 \
    && if [ $LFS_DOCS -eq 1 ]; then \
        mkdir -v -p /usr/share/doc/tcl-$VER; \
        cp -v -r  ../html/* /usr/share/doc/tcl-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/tcl

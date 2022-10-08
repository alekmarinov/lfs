#!/bin/bash
set -e
echo "Building perl.."
echo "Approximate build time: 9.4 SBU"
echo "Required disk space: 236 MB"

# 8.41. Perl
# The Perl package contains the Practical Extraction and Report Language.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/perl.html

VER=$(ls /sources/perl-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
VER_SHORT=${VER%.*}
tar -xf /sources/perl-*.tar.xz -C /tmp/ \
    && mv /tmp/perl-* /tmp/perl \
    && pushd /tmp/perl \
    && export BUILD_ZLIB=False \
    && export BUILD_BZIP2=0 \
    && sh Configure \
        -des \
        -Dprefix=/usr \
        -Dvendorprefix=/usr \
        -Dprivlib=/usr/lib/perl5/$VER_SHORT/core_perl \
        -Darchlib=/usr/lib/perl5/$VER_SHORT/core_perl \
        -Dsitelib=/usr/lib/perl5/$VER_SHORT/site_perl \
        -Dsitearch=/usr/lib/perl5/$VER_SHORT/site_perl \
        -Dvendorlib=/usr/lib/perl5/$VER_SHORT/vendor_perl \
        -Dvendorarch=/usr/lib/perl5/$VER_SHORT/vendor_perl \
        -Dman1dir=/usr/share/man/man1 \
        -Dman3dir=/usr/share/man/man3 \
        -Dpager="/usr/bin/less -isR" \
        -Duseshrplib \
        -Dusethreads \
    && make \
    && make install \
    && unset BUILD_ZLIB \
    && unset BUILD_BZIP2 \
    && popd \
    && rm -rf /tmp/perl

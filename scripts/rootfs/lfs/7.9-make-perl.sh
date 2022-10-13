#!/bin/bash
set -e
echo "Building perl.."
echo "Approximate build time: 1.6 SBU"
echo "Required disk space: 282 MB"

# 7.9. Perl
# The Perl package contains the Practical Extraction and Report Language.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter07/perl.html

VER=$(ls /sources/perl-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
VER_SHORT=${VER%.*}
tar -xf /sources/perl-*.tar.xz -C /tmp/ \
    && mv /tmp/perl-* /tmp/perl \
    && pushd /tmp/perl \
    && sh Configure -des \
        -Dprefix=/usr \
        -Dvendorprefix=/usr \
        -Dprivlib=/usr/lib/perl5/$VER_SHORT/core_perl \
        -Darchlib=/usr/lib/perl5/$VER_SHORT/core_perl \
        -Dsitelib=/usr/lib/perl5/$VER_SHORT/site_perl \
        -Dsitearch=/usr/lib/perl5/$VER_SHORT/site_perl \
        -Dvendorlib=/usr/lib/perl5/$VER_SHORT/vendor_perl \
        -Dvendorarch=/usr/lib/perl5/$VER_SHORT/vendor_perl \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/perl

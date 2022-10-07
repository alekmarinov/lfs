#!/bin/bash
set -e
echo "Building perl.."
echo "Approximate build time: 8.4 SBU"
echo "Required disk space: 257 MB"

# 6.40. Perl package contains the Practical Extraction and Report Language
tar -xf /sources/perl-*.tar.xz -C /tmp/ \
  && mv /tmp/perl-* /tmp/perl \
  && pushd /tmp/perl \
  && sh Configure -des                             \
      -Dprefix=/usr                                \
      -Dvendorprefix=/usr                          \
      -Dprivlib=/usr/lib/perl5/5.36/core_perl      \
      -Darchlib=/usr/lib/perl5/5.36/core_perl      \
      -Dsitelib=/usr/lib/perl5/5.36/site_perl      \
      -Dsitearch=/usr/lib/perl5/5.36/site_perl     \
      -Dvendorlib=/usr/lib/perl5/5.36/vendor_perl  \
      -Dvendorarch=/usr/lib/perl5/5.36/vendor_perl \
  && make \
  && make install \
  && popd \
  && rm -rf /tmp/perl

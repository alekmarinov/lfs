#!/bin/bash
set -e
echo "Building XML::Parser.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 2.3 MB"

# 8.42. XML::Parser
# The XML::Parser module is a Perl interface to James Clark's XML parser, Expat.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/xml-parser.html

tar -xf /sources/XML-Parser-*.tar.gz -C /tmp/ \
    && mv /tmp/XML-Parser-* /tmp/XML-Parser \
    && pushd /tmp/XML-Parser \
    && perl Makefile.PL \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make test; fi \
    && make install \
    && popd \
    && rm -rf /tmp/XML-Parser

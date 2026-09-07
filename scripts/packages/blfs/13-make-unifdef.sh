#!/bin/bash
# PACKAGE:  unifdef
# SOURCE:   unifdef-*.tar.gz
# RELEASE:  1
# CLASS:    bootstrap
set -e
echo "Building BLFS-unifdef.."

# unifdef
# Removes #ifdef'd code from C source. WebKit's build uses it to generate
# headers, so it is needed to compile WPE and nothing needs it afterwards.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/unifdef.html
#
# BUILD_REQUIRES:
# RUNTIME_REQUIRES:
# BUILD_ONLY: a source-preprocessing tool used while compiling webkit
#
# NOTE the constexpr rename. unifdef.c uses 'constexpr' as an identifier,
# which C23 - gcc 15's default - made a keyword.
#
# NOTE 'ln -s' becomes 'ln -sf' in the Makefile: the install relinks unifdefall
# every time, and without -f a second install into a tree that already has it
# fails.

rm -rf /tmp/unifdef
tar -xf /sources/unifdef-*.tar.gz -C /tmp/
mv /tmp/unifdef-* /tmp/unifdef
pushd /tmp/unifdef
sed -i 's/constexpr/unifdef_&/g' unifdef.c
sed -i 's/ln -s/ln -sf/' Makefile
make
make prefix=/usr install
popd
rm -rf /tmp/unifdef

#!/bin/bash
# PACKAGE:  libyaml
# SOURCE:   yaml-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-libyaml.."

# libyaml
# YAML parser. Ruby requires it, and ruby is what generates WebKit's bindings.
#
# NOTE the tarball is yaml-x.y.z.tar.gz but the package is libyaml - the
# SOURCE glob follows the file, the PACKAGE name follows the book.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/libyaml.html
#
# BUILD_REQUIRES:
# RUNTIME_REQUIRES:

rm -rf /tmp/libyaml
tar -xf /sources/yaml-*.tar.gz -C /tmp/
mv /tmp/yaml-* /tmp/libyaml
pushd /tmp/libyaml
./configure --prefix=/usr --disable-static
make
make install
popd
rm -rf /tmp/libyaml

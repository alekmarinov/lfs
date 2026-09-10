#!/bin/bash
# PACKAGE:  opus
# SOURCE:   opus-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-opus.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 40 MB"

# opus
# The audio codec YouTube serves with VP9. Without it the browser negotiates a
# stream it cannot decode, and WebKit's failure to build the pipeline is not
# graceful: gst_element_factory_make returns NULL, a signal is connected to it
# and the web process dies with G_TYPE_CHECK_INSTANCE.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/multimedia/opus.html
#
# BUILD_REQUIRES: 8.69-make-make
# RUNTIME_REQUIRES:

rm -rf /tmp/opus
tar -xf /sources/opus-*.tar.gz -C /tmp/
mv /tmp/opus-[0-9]* /tmp/opus
pushd /tmp/opus
./configure --prefix=/usr --disable-static
make
make install
popd
rm -rf /tmp/opus

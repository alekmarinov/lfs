#!/bin/bash
# PACKAGE:  ruby
# SOURCE:   ruby-*.tar.xz
# RELEASE:  1
# CLASS:    bootstrap
set -e
echo "Building BLFS-ruby.."
echo "Approximate build time: 4 SBU"

# ruby
# WebKit generates a large part of its C++ from IDL using ruby scripts, so it
# cannot be compiled without one. Nothing here runs ruby at runtime.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/ruby.html
#
# BUILD_REQUIRES: 9-make-libyaml 8.48-make-openssl 8.50-make-libffi 22-make-sqlite
# RUNTIME_REQUIRES:
# BUILD_ONLY: webkit's bindings generator; no ruby code ships in any image
#
# NOTE --without-baseruby makes it bootstrap with the interpreter it builds
# rather than looking for one already installed, which there is not.
#
# NOTE ac_cv_func_qsort_r=no is the book's. glibc's qsort_r has a different
# argument order from the BSD one ruby probes for, and letting the probe
# succeed gives a sort that corrupts its input.

VER=$(basename "$(ls /sources/ruby-[0-9]*.tar.xz)" .tar.xz | sed 's/^ruby-//')
rm -rf /tmp/ruby
tar -xf /sources/ruby-[0-9]*.tar.xz -C /tmp/
mv /tmp/ruby-$VER /tmp/ruby
pushd /tmp/ruby
./configure --prefix=/usr \
    --disable-rpath \
    --enable-shared \
    --without-valgrind \
    --without-baseruby \
    ac_cv_func_qsort_r=no \
    --docdir=/usr/share/doc/ruby-$VER
make
make install
popd
rm -rf /tmp/ruby

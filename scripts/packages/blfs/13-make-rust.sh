#!/bin/bash
set -e
echo "Building BLFS-rust.."
echo "Approximate build time: 5 SBU"
echo "Required disk space: 9 GB"

# 13. rust
# Firefox is written partly in rust and cannot be built without it. Nothing
# else here needs it, and it is not installed into any distro - it is a build
# tool, like nasm and mako.
#
# https://www.linuxfromscratch.org/blfs/view/11.2/general/rust.html
#
# BUILD_REQUIRES: 13-make-llvm 7.10-make-python 17-make-curl 8.46-make-openssl 4-make-ca-certificates
# RUNTIME_REQUIRES:
# BUILD_ONLY: the rust code in firefox is compiled into libxul, there is no rust runtime to ship
#
# NOTE link-shared = true uses the llvm already built here rather than the copy
# bundled in the rust source. That is the difference between a five hour build
# and a nine hour one.
#
# NOTE x.py downloads a stage0 compiler to bootstrap with, so this build needs
# the network and a working trust store - which is what 4-make-ca-certificates
# is for. Everything else is vendored in the source tarball.
#
# NOTE only cargo is built alongside rustc. clippy and rustfmt are developer
# tools which nothing in this build uses, and each one costs time.
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

VER=1.62.1

rm -rf /tmp/rustc
tar -xf /sources/rustc-$VER-src.tar.xz -C /tmp/
mv /tmp/rustc-$VER-src /tmp/rustc
pushd /tmp/rustc

cat > config.toml << "ENDCONFIG"
[llvm]
link-shared = true

[build]
docs = false
extended = true
tools = ["cargo"]

[install]
prefix = "/usr"

[rust]
channel = "stable"
rpath = false
codegen-tests = false
debuginfo-level-rustc = 0

[target.x86_64-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"
ENDCONFIG

python3 ./x.py build
python3 ./x.py install

popd
rm -rf /tmp/rustc

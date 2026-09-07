#!/bin/bash
# PACKAGE:  rust
# SOURCE:   rustc-*-src.tar.xz
# RELEASE:  1
# CLASS:    bootstrap
set -e
echo "Building BLFS-rust.."
echo "Approximate build time: 5 SBU"
echo "Required disk space: 9 GB"

# 13. rust
# Firefox is written partly in rust and cannot be built without it. Nothing
# else here needs it, and it is not installed into any distro - it is a build
# tool, like nasm and mako.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/general/rust.html
#
# BUILD_REQUIRES: 13-make-llvm 7.10-make-python 17-make-curl 8.48-make-openssl x-make-ca-certificates
# RUNTIME_REQUIRES:
# BUILD_ONLY: the rust code in firefox is compiled into libxul, there is no rust runtime to ship
#
# NOTE link-shared = true uses the llvm already built here rather than the copy
# bundled in the rust source. That is the difference between a five hour build
# and a nine hour one.
#
# NOTE x.py downloads a stage0 compiler to bootstrap with, so this build needs
# the network and a working trust store - which is what x-make-ca-certificates
# is for. Everything else is vendored in the source tarball.
#
# NOTE only cargo is built alongside rustc. clippy and rustfmt are developer
# tools which nothing in this build uses, and each one costs time.
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

# Derived, not hardcoded. It was pinned to 1.62.1 and silently went looking
# for a tarball that the port had replaced.
VER=$(basename "$(ls /sources/rustc-[0-9]*-src.tar.xz)" -src.tar.xz | sed 's/^rustc-//')

rm -rf /tmp/rustc
tar -xf /sources/rustc-$VER-src.tar.xz -C /tmp/
mv /tmp/rustc-$VER-src /tmp/rustc
pushd /tmp/rustc

# NOTE bootstrap.toml, not config.toml. Rust renamed the file; 1.89 reads
# bootstrap.toml and a leftover config.toml is ignored, so the build would
# quietly use defaults - which means building the bundled llvm from scratch
# instead of linking the one already here.
#
# NOTE change-id. x.py warns and stops on an unreviewed config unless this
# matches the value the release expects; it is the book's for 1.89.
#
# NOTE locked-deps. Stops cargo querying crates.io for newer versions of the
# vendored dependencies. The stage0 compiler is still downloaded, which is why
# this build needs the network and x-make-ca-certificates.
cat > bootstrap.toml << "ENDCONFIG"
change-id = 142379

[llvm]
link-shared = true

[build]
docs = false
extended = true
locked-deps = true
tools = ["cargo"]

[install]
prefix = "/usr"

[rust]
channel = "stable"
rpath = false
codegen-tests = false
debuginfo-level-rustc = 0
lld = false
llvm-bitcode-linker = false

[target.x86_64-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"
ENDCONFIG

# these make cargo use the system libraries if they happen to be present,
# rather than compiling vendored copies
[ ! -e /usr/include/libssh2.h ]  || export LIBSSH2_SYS_USE_PKG_CONFIG=1
[ ! -e /usr/include/sqlite3.h ]  || export LIBSQLITE3_SYS_USE_PKG_CONFIG=1

python3 ./x.py build
python3 ./x.py install

popd
rm -rf /tmp/rustc

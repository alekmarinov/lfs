#!/bin/bash
set -e
echo "Building BLFS-cbindgen.."

# cbindgen
# Generates the C headers which let the C++ side of Firefox call into its rust
# side. Firefox will not configure without it. Build only.
#
# NOTE this is the one build here which is not reproducible from pinned
# sources. cargo resolves and downloads the crates cbindgen depends on from
# crates.io while it builds - they are not vendored in the tarball the way the
# rust source is. It needs the network and the trust store from
# 4-make-ca-certificates, and what it fetches is whatever crates.io serves at
# the time, within the bounds of Cargo.lock.
#
# BUILD_REQUIRES: 13-make-rust 4-make-ca-certificates
# RUNTIME_REQUIRES:
# BUILD_ONLY: generates headers during firefox's build and is never run again
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/cbindgen
tar -xf /sources/cbindgen-*.tar.gz -C /tmp/
mv /tmp/cbindgen-* /tmp/cbindgen
pushd /tmp/cbindgen
# --locked: build against the versions in Cargo.lock rather than letting
# cargo resolve to whatever is newest today. Without it the crates cbindgen
# is built from drift years forward from the ones it was released with, and
# the headers it generates can stop matching what firefox expects.
cargo build --release --locked
install -v -m755 target/release/cbindgen /usr/bin/cbindgen
popd
rm -rf /tmp/cbindgen

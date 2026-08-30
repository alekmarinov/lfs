#!/bin/bash
set -e
echo "Generating the CA trust store.."

# 4. ca-certificates
# make-ca installs the tool which builds a trust store, but never builds one,
# so /etc/ssl/certs was empty: nothing in the image could verify an https
# certificate, and neither could anything in the build - cargo fetching crates
# fails with "unable to get local issuer certificate".
#
# make-ca -g would download Mozilla's list itself. It is fetched with the rest
# of the sources instead, so the store is built from a file with a known
# checksum rather than from whatever the network returns during a build.
#
# BUILD_REQUIRES: 4-make-make-ca 4-make-p11-kit 4-make-nss 8.48-make-openssl
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

install -vdm755 /etc/ssl/local
/usr/sbin/make-ca -C /sources/certdata.txt -f

echo "trust anchors: $(ls /etc/ssl/certs/*.pem 2>/dev/null | wc -l)"

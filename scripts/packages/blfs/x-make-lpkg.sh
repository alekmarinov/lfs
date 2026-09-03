#!/bin/bash
# PACKAGE:  lpkg
# VERSION:  5
# RELEASE:  1
# CLASS:    system
set -e
echo "Building lpkg.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 1 MB"

# The package manager, as a package.
#
# CLASS is 'system', not 'core', so lpkg can replace itself on a running
# machine. The core restriction exists because a libc cannot be swapped under
# the processes using it; a shell script can, provided the replacement is a
# new inode rather than a rewrite of the old one. lpkg extracts with
# --unlink-first for exactly that reason, so the shell running the upgrade
# keeps reading the file it started from and the next invocation is the new
# one.
#
# It belongs in the core because it costs nothing to put there: every command
# it runs - bash, coreutils, grep, sed, gawk, findutils, tar, util-linux and
# openssl - is already in the core for other reasons. Measured, the marginal
# cost of this package is the 40 KB of shell below.
#
# Two things it can use and does not require:
#
#   curl      only for an http or https channel. A REPO_URL which is a path or
#             a file:// URL is copied instead, so a system fed from removable
#             media or an NFS mount needs nothing extra. Adding curl to the
#             core costs 4 MB and pulls in nothing that is not already there.
#
#   readelf   only for 'lpkg build', to read the sonames out of a package
#             compiled here. It lives in binutils, whose runtime closure pulls
#             gcc: 1800 MB, against a core of 681 MB. Not worth it for one
#             command, so lpkg says so and carries on when it is missing.
#
# There is nothing to compile. The sources are the scripts of this repository,
# which build-package.sh has already staged into the build base - so they are
# at /scripts inside the chroot, the same place 'make update-scripts' puts
# them. Run that first if this package is rebuilt after editing lpkg.
#
# NOTE the version here has to be bumped by hand when lpkg changes, and the
# usual guard does not cover it: 'make repo' notices a recipe whose text
# changed without a RELEASE bump, and this recipe does not change when the
# script it installs does. Bump VERSION with lpkg's own VERSION variable.

install -Dm755 /scripts/lpkg/lpkg                   /usr/bin/lpkg

# The soname scanner, shared with the build host so that a package compiled by
# 'lpkg build' describes itself exactly the way build-package.sh makes one.
install -Dm644 /scripts/packages/pkg-elf.sh         /usr/lib/lpkg/pkg-elf.sh

# The table that says what happens when several packages ship one file. The
# same file build-distro.sh assembles a rootfs with: two implementations of it
# would drift, and the symptom is a system whose /etc/passwd has lost the
# accounts its services need.
install -Dm644 /scripts/packages/file-policy.conf   /etc/lpkg/file-policy.conf

# /etc/lpkg/lpkg.conf and /etc/lpkg/trusted.pub are deliberately not here.
# They are the identity of a particular installation - which channel it reads
# and which key it trusts - not content of this package, and build-distro.sh
# writes them when it assembles a distro. A key shipped in the package that
# verifies the channel would also be a key anyone rebuilding the package could
# replace.
install -d -m755 /var/lib/lpkg /var/cache/lpkg

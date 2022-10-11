#!/bin/bash
set -e
echo "Preparing environment.."

# download sources
sh /scripts/prepare/3.1-download.sh

# build toolchain
sh /scripts/prepare/5.2-make-binutils.sh
sh /scripts/prepare/5.3-make-gcc.sh
sh /scripts/prepare/5.4-make-linux-api-headers.sh
sh /scripts/prepare/5.5-make-glibc.sh
sh /scripts/prepare/5.6-make-libstdc.sh
sh /scripts/prepare/6.2-make-m4.sh
sh /scripts/prepare/6.3-make-ncurses.sh
sh /scripts/prepare/6.4-make-bash.sh
sh /scripts/prepare/6.5-make-coreutils.sh
sh /scripts/prepare/6.6-make-diffutils.sh
sh /scripts/prepare/6.7-make-file.sh
sh /scripts/prepare/6.8-make-findutils.sh
sh /scripts/prepare/6.9-make-gawk.sh
sh /scripts/prepare/6.10-make-grep.sh
sh /scripts/prepare/6.11-make-gzip.sh
sh /scripts/prepare/6.12-make-make.sh
sh /scripts/prepare/6.13-make-patch.sh
sh /scripts/prepare/6.14-make-sed.sh
sh /scripts/prepare/6.15-make-tar.sh
sh /scripts/prepare/6.16-make-xz.sh
sh /scripts/prepare/6.17-make-binutils.sh
sh /scripts/prepare/6.18-make-gcc.sh

echo "run-prepare.sh /scripts/prepare/finished."

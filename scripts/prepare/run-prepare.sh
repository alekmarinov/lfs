#!/bin/bash
set -e
echo "Preparing environment.."

# download toolchain
sh /tools/prepare/3.1-download-tools.sh

# build toolchain
sh /tools/prepare/5.2-make-binutils.sh
sh /tools/prepare/5.3-make-gcc.sh
sh /tools/prepare/5.4-make-linux-api-headers.sh
sh /tools/prepare/5.5-make-glibc.sh
sh /tools/prepare/5.6-make-libstdc.sh
sh /tools/prepare/6.2-make-m4.sh
sh /tools/prepare/6.3-make-ncurses.sh
sh /tools/prepare/6.4-make-bash.sh
sh /tools/prepare/6.5-make-coreutils.sh
sh /tools/prepare/6.6-make-diffutils.sh
sh /tools/prepare/6.7-make-file.sh
sh /tools/prepare/6.8-make-findutils.sh
sh /tools/prepare/6.9-make-gawk.sh
sh /tools/prepare/6.10-make-grep.sh
sh /tools/prepare/6.11-make-gzip.sh
sh /tools/prepare/6.12-make-make.sh
sh /tools/prepare/6.13-make-patch.sh
sh /tools/prepare/6.14-make-sed.sh
sh /tools/prepare/6.15-make-tar.sh
sh /tools/prepare/6.16-make-xz.sh
sh /tools/prepare/6.17-make-binutils.sh
sh /tools/prepare/6.18-make-gcc.sh

echo "run-prepare.sh /tools/prepare/finished."

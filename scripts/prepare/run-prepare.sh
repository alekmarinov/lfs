#!/bin/bash
set -e
echo "Preparing environment.."

build="sh $LFS/scripts/build.sh"

# download sources
$build $LFS/scripts/prepare/3.1-download.sh

# build toolchain
$build $LFS/scripts/prepare/5.2-make-binutils.sh
$build $LFS/scripts/prepare/5.3-make-gcc.sh
$build $LFS/scripts/prepare/5.4-make-linux-api-headers.sh
$build $LFS/scripts/prepare/5.5-make-glibc.sh
$build $LFS/scripts/prepare/5.6-make-libstdc.sh
$build $LFS/scripts/prepare/6.2-make-m4.sh
$build $LFS/scripts/prepare/6.3-make-ncurses.sh
$build $LFS/scripts/prepare/6.4-make-bash.sh
$build $LFS/scripts/prepare/6.5-make-coreutils.sh
$build $LFS/scripts/prepare/6.6-make-diffutils.sh
$build $LFS/scripts/prepare/6.7-make-file.sh
$build $LFS/scripts/prepare/6.8-make-findutils.sh
$build $LFS/scripts/prepare/6.9-make-gawk.sh
$build $LFS/scripts/prepare/6.10-make-grep.sh
$build $LFS/scripts/prepare/6.11-make-gzip.sh
$build $LFS/scripts/prepare/6.12-make-make.sh
$build $LFS/scripts/prepare/6.13-make-patch.sh
$build $LFS/scripts/prepare/6.14-make-sed.sh
$build $LFS/scripts/prepare/6.15-make-tar.sh
$build $LFS/scripts/prepare/6.16-make-xz.sh
$build $LFS/scripts/prepare/6.17-make-binutils.sh
$build $LFS/scripts/prepare/6.18-make-gcc.sh

echo "run-prepare.sh finished."

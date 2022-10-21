#!/bin/bash
set -e
echo "Building tools..."

$LFS_BASE/scripts/2-version-check.sh

build="$LFS_BASE/scripts/build.sh"

# download sources
$build -t $LFS_BASE/scripts/tools/3.1-download.sh

# build tools
$build -t $LFS_BASE/scripts/tools/4.2-make-structure.sh
$build -t $LFS_BASE/scripts/tools/5.2-make-binutils.sh
$build -t $LFS_BASE/scripts/tools/5.3-make-gcc.sh
$build -t $LFS_BASE/scripts/tools/5.4-make-linux-api-headers.sh
$build -t $LFS_BASE/scripts/tools/5.5-make-glibc.sh
$build -t $LFS_BASE/scripts/tools/5.6-make-libstdc.sh
$build -t $LFS_BASE/scripts/tools/6.2-make-m4.sh
$build -t $LFS_BASE/scripts/tools/6.3-make-ncurses.sh
$build -t $LFS_BASE/scripts/tools/6.4-make-bash.sh
$build -t $LFS_BASE/scripts/tools/6.5-make-coreutils.sh
$build -t $LFS_BASE/scripts/tools/6.6-make-diffutils.sh
$build -t $LFS_BASE/scripts/tools/6.7-make-file.sh
$build -t $LFS_BASE/scripts/tools/6.8-make-findutils.sh
$build -t $LFS_BASE/scripts/tools/6.9-make-gawk.sh
$build -t $LFS_BASE/scripts/tools/6.10-make-grep.sh
$build -t $LFS_BASE/scripts/tools/6.11-make-gzip.sh
$build -t $LFS_BASE/scripts/tools/6.12-make-make.sh
$build -t $LFS_BASE/scripts/tools/6.13-make-patch.sh
$build -t $LFS_BASE/scripts/tools/6.14-make-sed.sh
$build -t $LFS_BASE/scripts/tools/6.15-make-tar.sh
$build -t $LFS_BASE/scripts/tools/6.16-make-xz.sh
$build -t $LFS_BASE/scripts/tools/6.17-make-binutils.sh
$build -t $LFS_BASE/scripts/tools/6.18-make-gcc.sh

echo "Building tools environment finished"

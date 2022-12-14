#!/bin/bash
set -e
echo "Building tools..."

# in .env the LFS_BASE is defined relatively but 
# --prefix option in configure requires absolute path
export LFS_BASE=$(realpath $LFS_BASE)

$LFS_BASE/scripts/2-version-check.sh

build="$LFS_BASE/scripts/tools/build-tool.sh"

# download sources
$build $LFS_BASE/scripts/tools/3.1-download.sh

# build tools
$build $LFS_BASE/scripts/tools/4.2-make-structure.sh
$build $LFS_BASE/scripts/tools/5.2-make-binutils.sh
$build $LFS_BASE/scripts/tools/5.3-make-gcc.sh
$build $LFS_BASE/scripts/tools/5.4-make-linux-api-headers.sh
$build $LFS_BASE/scripts/tools/5.5-make-glibc.sh
$build $LFS_BASE/scripts/tools/5.6-make-libstdc.sh
$build $LFS_BASE/scripts/tools/6.2-make-m4.sh
$build $LFS_BASE/scripts/tools/6.3-make-ncurses.sh
$build $LFS_BASE/scripts/tools/6.4-make-bash.sh
$build $LFS_BASE/scripts/tools/6.5-make-coreutils.sh
$build $LFS_BASE/scripts/tools/6.6-make-diffutils.sh
$build $LFS_BASE/scripts/tools/6.7-make-file.sh
$build $LFS_BASE/scripts/tools/6.8-make-findutils.sh
$build $LFS_BASE/scripts/tools/6.9-make-gawk.sh
$build $LFS_BASE/scripts/tools/6.10-make-grep.sh
$build $LFS_BASE/scripts/tools/6.11-make-gzip.sh
$build $LFS_BASE/scripts/tools/6.12-make-make.sh
$build $LFS_BASE/scripts/tools/6.13-make-patch.sh
$build $LFS_BASE/scripts/tools/6.14-make-sed.sh
$build $LFS_BASE/scripts/tools/6.15-make-tar.sh
$build $LFS_BASE/scripts/tools/6.16-make-xz.sh
$build $LFS_BASE/scripts/tools/6.17-make-binutils.sh
$build $LFS_BASE/scripts/tools/6.18-make-gcc.sh

echo "Building tools environment finished"

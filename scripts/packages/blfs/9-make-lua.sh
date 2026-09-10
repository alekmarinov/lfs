#!/bin/bash
# PACKAGE:  lua
# SOURCE:   lua-*.tar.gz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-lua.."
echo "Approximate build time: less than 0.1 SBU"
echo "Required disk space: 10 MB"

# lua
# Here for weston's lua-shell, which requires Lua 5.4 or newer and is what
# turns window arrangement from a fixed policy into a script: the shell hands
# the script surface_added, relayout and set_fullscreen, and the script places
# and stacks the views. Nothing else in this tree uses Lua yet.
#
# https://www.lua.org/
#
# BUILD_REQUIRES: 8.69-make-make 8.30-make-ncurses 8.12-make-readline
# RUNTIME_REQUIRES:
#
# NOTE upstream ships no pkg-config file and meson's dependency('lua') looks
# for one, so it is written here. Both names are installed: meson tries
# several, and which one it settles on has changed between releases.
#
# NOTE -fPIC. Upstream builds only a static liblua.a, and weston links it into
# lua-shell.so - a shared object. Without position independent code that link
# fails, and the error names a relocation rather than the cause.

rm -rf /tmp/lua
tar -xf /sources/lua-*.tar.gz -C /tmp/
mv /tmp/lua-[0-9]* /tmp/lua
pushd /tmp/lua
make linux MYCFLAGS="-fPIC" MYLIBS="-lncursesw"
make install INSTALL_TOP=/usr
# Composed from the three parts, because LUA_RELEASE is not a literal: it is
# defined as LUA_VERSION "." LUA_VERSION_RELEASE, so matching a version string
# against it finds nothing and leaves Version: empty in the .pc file. meson
# then reports Lua as "not found" when it is installed and only its version is
# missing, which is a long way from the cause.
V=$(sed -n 's/^#define LUA_VERSION_MAJOR[[:space:]]*"\([0-9]*\)".*/\1/p' src/lua.h | head -1)
R=$(sed -n 's/^#define LUA_VERSION_MINOR[[:space:]]*"\([0-9]*\)".*/\1/p' src/lua.h | head -1)
P=$(sed -n 's/^#define LUA_VERSION_RELEASE[[:space:]]*"\([0-9]*\)".*/\1/p' src/lua.h | head -1)
FULL="$V.$R.$P"
[ -n "$V" ] && [ -n "$R" ] && [ -n "$P" ] || { echo "cannot read the version from src/lua.h"; exit 1; }
mkdir -p /usr/lib/pkgconfig
for name in lua lua${V}.${R}; do
cat > /usr/lib/pkgconfig/${name}.pc <<PC
prefix=/usr
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: Lua
Description: An extensible extension language
Version: ${FULL}
Libs: -L\${libdir} -llua -lm -ldl
Cflags: -I\${includedir}
PC
done
grep -q "^Version: [0-9]" /usr/lib/pkgconfig/lua.pc || { echo "lua.pc has no version"; exit 1; }
popd
rm -rf /tmp/lua

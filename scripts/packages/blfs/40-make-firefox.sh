#!/bin/bash
# PACKAGE:  firefox
# SOURCE:   firefox-*.source.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-firefox.."
echo "Approximate build time: 20 SBU"
echo "Required disk space: 8 GB"

# 27. firefox
# The browser. Everything from Mesa upwards was built for this: gtk3 is its
# only toolkit on linux, gtk3 needs libepoxy, and libepoxy needs OpenGL.
#
# https://www.linuxfromscratch.org/blfs/view/11.2/xsoft/firefox.html
#
# BUILD_REQUIRES: 25-make-gtk3 9-make-dbus-glib 13-make-rust 13-make-cbindgen 9-make-nodejs 13-make-nasm 12-make-zip 12-make-unzip 42-make-alsa-lib 13-make-llvm 9-make-icu 4-make-nss 9-make-nspr 22-make-sqlite
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

. /etc/profile.d/xorg.sh

rm -rf /tmp/firefox
tar -xf /sources/firefox-*.source.tar.xz -C /tmp/
mv /tmp/firefox-* /tmp/firefox
pushd /tmp/firefox

# Build under python3.10, installed alongside the system 3.13 for exactly this.
# Firefox 102 predates the removal of distutils, pipes, imp and
# pkgutil.ImpImporter, and reaches for all of them - from its vendored pip and
# pkg_resources as much as from its own code. mach uses whichever interpreter
# starts it, so naming that interpreter is the whole fix.
PY=python3.10
$PY --version

# mach keeps its state and its python virtualenv here. Without it being set,
# it writes to $HOME, which is /root in the chroot and works, but keeping it
# under /tmp means the whole build disappears with the source tree.
export MOZBUILD_STATE_PATH=/tmp/mozbuild
export SHELL=/bin/bash

# glibc 2.36 added arc4random, arc4random_buf and arc4random_uniform to
# stdlib.h. The copy of libevent bundled in ipc/chromium includes arc4random.c
# with ARC4RANDOM_EXPORT defined as static, and while it disables arc4random
# and arc4random_uniform through ARC4RANDOM_NORANDOM and NOUNIFORM, there is no
# such switch for arc4random_buf - so it is compiled as a static definition of
# a function glibc has already declared extern, and clang stops with "static
# declaration follows non-static declaration".
#
# The definition is guarded out on a glibc which provides its own. Callers
# inside libevent then use that one, which is a better source of randomness
# than the RC4 implementation being skipped here.
python3 - << "ENDPATCH"
import io
p = "ipc/chromium/src/third_party/libevent/arc4random.c"
s = io.open(p, encoding="utf-8").read()
head = "ARC4RANDOM_EXPORT void\narc4random_buf(void *buf_, size_t n)\n{"
assert s.count(head) == 1, "arc4random_buf not found as expected"
guard = "#if !defined(__GLIBC__) || __GLIBC__ < 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ < 36)\n"
i = s.index(head)
s = s[:i] + guard + s[i:]
end = "\tARC4_UNLOCK_();\n}\n"
j = s.index(end, i) + len(end)
s = s[:j] + "#endif\n" + s[j:]
io.open(p, "w", encoding="utf-8").write(s)
print("  arc4random_buf guarded for glibc >= 2.36")
ENDPATCH

# webrender_ffi.h defines ROOT_CLIP_CHAIN by hand, and cbindgen.toml asks for
# constants to be exported from the rust crates it parses - which include the
# same constant. The generated header and the hand written one then both define
# it and every file including both fails to compile with "redefinition of
# 'ROOT_CLIP_CHAIN'". Telling cbindgen to leave that one alone keeps the hand
# written definition, which is the one the C++ side has always used.
#
# NOTE this is a local workaround. Upstream builds this combination without
# complaint and I have not established what differs here.
sed -i 's/^include = \["POLYGON_CLIP_VERTEX_MAX"\]$/include = ["POLYGON_CLIP_VERTEX_MAX"]\nexclude = ["ROOT_CLIP_CHAIN"]/' \
    gfx/webrender_bindings/cbindgen.toml
grep -q 'exclude = \["ROOT_CLIP_CHAIN"\]' gfx/webrender_bindings/cbindgen.toml

cat > mozconfig << "ENDCONFIG"
ac_add_options --prefix=/usr
ac_add_options --enable-application=browser
ac_add_options --enable-official-branding
ac_add_options --enable-optimize
ac_add_options --disable-debug
ac_add_options --disable-debug-symbols
ac_add_options --disable-tests

# nothing here can act on a crash report or apply an update
ac_add_options --disable-crashreporter
ac_add_options --disable-updater

# alsa is the audio backend the kernel already provides, which avoids
# pulseaudio and the daemon that comes with it
ac_add_options --enable-audio-backends=alsa

# the libraries which are already built here are used instead of the copies
# bundled in the firefox source. png is deliberately not among them: firefox
# wants libpng with the APNG patch applied and ours is the plain upstream one,
# so its bundled copy is used for that one.
ac_add_options --with-system-nspr
ac_add_options --with-system-nss
ac_add_options --with-system-icu
ac_add_options --with-system-jpeg
ac_add_options --with-system-zlib

# webrtc is a large part of the build and nothing here uses video calls. It can
# be turned back on at the cost of build time.
ac_add_options --disable-webrtc

# lld is not built by our llvm package, so the GNU linker is used. Linking
# libxul with it wants several gigabytes of memory.
ac_add_options --enable-linker=bfd

ac_add_options --without-wasm-sandboxed-libraries

# Rect.h and others reach for std::int32_t without including <cstdint>. That
# used to arrive through some other header and no longer does, so it is forced
# into every translation unit instead of patching each site.
export CXXFLAGS="-include cstdint"

mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/objdir
mk_add_options AUTOCLOBBER=1
ENDCONFIG

$PY ./mach build
$PY ./mach install

popd
rm -rf /tmp/firefox /tmp/mozbuild

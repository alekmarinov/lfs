#!/bin/bash
# PACKAGE:  firefox
# SOURCE:   firefox-*.source.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-firefox.."
echo "Approximate build time: 30 SBU"
echo "Required disk space: 10 GB"

# 27. firefox
# The browser. Everything from Mesa upwards was built for this: gtk3 is its
# only toolkit on linux, gtk3 needs libepoxy, and libepoxy needs OpenGL.
#
# https://www.linuxfromscratch.org/blfs/view/12.4/xsoft/firefox.html
#
# BUILD_REQUIRES: 25-make-gtk3 9-make-dbus-glib 13-make-rust 13-make-cbindgen 9-make-nodejs 13-make-nasm 12-make-zip 25-make-libnotify 25-make-startup-notification 42-make-alsa-lib 13-make-llvm 9-make-icu 4-make-nss 9-make-nspr 22-make-sqlite
# RUNTIME_REQUIRES:
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.
#
# NOTE this is 140esr. Going from 102esr took the whole toolchain with it -
# rust 1.89, llvm 20, nodejs 22, cbindgen 0.29 - and retired three workarounds
# which were all about 102 being old:
#
#   the second python. 102's mach reached for imp, distutils and
#   pkgutil.ImpImporter from its vendored pip, all removed in 3.13, so a
#   python3.10 was built and kept solely to run this build. 140 wants exactly
#   the 3.13 that LFS 12.4 installs, so that package is gone.
#
#   the arc4random_buf guard. 102 bundled a libevent old enough to define a
#   function glibc 2.36 had started declaring itself. 140's copy is new enough
#   to know about it.
#
#   the ROOT_CLIP_CHAIN cbindgen exclusion, which was a local workaround for a
#   redefinition upstream did not see. It does not reproduce here on 140.

. /etc/profile.d/xorg.sh

rm -rf /tmp/firefox
tar -xf /sources/firefox-*.source.tar.xz -C /tmp/
mv /tmp/firefox-* /tmp/firefox
pushd /tmp/firefox

# mach keeps its state and its python virtualenv here. Without it being set it
# writes to $HOME, which is /root in the chroot and works, but keeping it under
# the source tree means the whole build disappears with it.
export MOZBUILD_STATE_PATH=/tmp/mozbuild
export SHELL=/bin/bash

# The build has no network. Left to itself mach downloads its own python
# packages into the virtualenv on first run and fails; this tells it to use
# what is already installed.
export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=none

# NOTE MOZ_NOSPAM. Without it mach tries to pop up a desktop notification when
# a build or install finishes, by running notify-send. There is no notification
# daemon in a chroot, and what happens is worse than a failure: notify-send
# exits, mach's ProcessReaderStdout thread dies with
#   ValueError: I/O operation on closed file
# and the main thread then waits on it forever. 'mach install' hangs after
# printing "Install complete", with the install already correctly on disk, and
# nothing ever exits. It sat like that for 16 hours here.
#
# mozbuild checks for this variable before notifying at all (base.py), so
# setting it removes the call rather than papering over the deadlock.
export MOZ_NOSPAM=1

# The python configure step uses POSIX semaphores, which need a real /dev/shm.
# Without it the failure is a traceback inside multiprocessing/synchronize.py
# rather than anything naming the mount.
mountpoint -q /dev/shm || mount -t tmpfs devshm /dev/shm

cat > mozconfig << "ENDCONFIG"
ac_add_options --prefix=/usr
ac_add_options --enable-application=browser
ac_add_options --enable-official-branding
ac_add_options --disable-crashreporter
ac_add_options --disable-updater
ac_add_options --disable-tests
ac_add_options --disable-debug-symbols

# no wireless-tools here, so the wifi scan backend has nothing to talk to
ac_add_options --disable-necko-wifi

# alsa is what the kernel already provides; pulseaudio would bring a daemon
ac_add_options --enable-audio-backends=alsa

# System copies of what is already built here. libevent, libvpx and webp are
# deliberately absent from this list - BLFS recommends them and they are not
# packaged here, so firefox uses its bundled copies of those three.
ac_add_options --with-system-icu
ac_add_options --with-system-nspr
ac_add_options --with-system-nss
ac_add_options --with-system-jpeg
ac_add_options --with-system-png
ac_add_options --with-system-zlib
ac_add_options --enable-system-ffi
ac_add_options --enable-system-pixman

# --with-system-png needs libpng built with the APNG patch, which the libpng
# package here applies. On 102 this was left bundled for exactly that reason.

# SIMD in the shipped encoding_rs crate
ac_add_options --enable-rust-simd

# Moved out of mozilla automation into all builds; it wants extra llvm pieces
# and slows the build considerably.
ac_add_options --without-wasm-sandboxed-libraries

# webrtc is deliberately LEFT ENABLED, which is a change from the 102 recipe.
#
# That one passed --disable-webrtc, on the grounds that it is a large part of
# the build and nothing here used video calls. It is wanted now: without it
# Firefox cannot do video conferencing at all - no Meet, no Jitsi, no getUserMedia
# - and for a desktop image that is a real hole rather than a saving.
#
# The cost is build time and package size. If it is ever traded away again,
# put --disable-webrtc back here rather than deleting this note, so the next
# reader knows which way the decision went and why.

# lld is not built by our llvm package, so the GNU linker is used. Linking
# libxul with it wants several gigabytes of memory.
ac_add_options --enable-linker=bfd

unset MOZ_TELEMETRY_REPORTING

mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/objdir
mk_add_options AUTOCLOBBER=1

# without this the window class is firefox-default and the icon does not match
MOZ_APP_REMOTINGNAME=firefox
ENDCONFIG

./mach build
./mach install

# Proof the install actually landed, rather than trusting mach's exit status.
# mach has been seen to finish its work and then fail to exit; the inverse -
# exiting 0 having installed nothing - would be worse and silent.
[ -x /usr/lib/firefox/firefox ] || {
    echo "mach install exited but /usr/lib/firefox/firefox is not there."
    exit 1
}

popd
rm -rf /tmp/firefox /tmp/mozbuild

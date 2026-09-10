#!/bin/bash
# PACKAGE:  weston
# SOURCE:   weston-*.tar.xz
# RELEASE:  1
# CLASS:    extra
set -e
echo "Building BLFS-weston.."
echo "Approximate build time: 1.0 SBU"
echo "Required disk space: 300 MB"

# weston
# A Wayland compositor, so the browser can stop being one.
#
# cog has two platforms. The DRM one draws straight to KMS with nothing in
# between, which is why this distro started there - but it is the backend
# upstream exercises least, and it shows: no fullscreen handling at all, a
# cursor path that cannot find its plane, and a crash on any connector with no
# modes. The Wayland platform is the one everyone else runs.
#
# Weston rather than cage: cage is small but sits on wlroots, and wlroots is
# neither small nor stable across releases. Weston's dependencies were already
# in this tree except libseat, and it is the reference implementation.
#
# https://gitlab.freedesktop.org/wayland/weston
#
# BUILD_REQUIRES: 9-make-seatd 9-make-lua 24-make-wayland 24-make-wayland-protocols 24-make-libxkbcommon 24-make-mesa 24-make-libdrm 10-make-pixman 9-make-libinput 9-make-libevdev 9-make-lcms2 8.76-make-udev 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE only the DRM backend. The others drive weston inside X, inside another
# Wayland session, or over RDP and VNC - none of which exist on this machine,
# and each of which is a dependency and an attack surface for a feature nobody
# can reach.
#
# NOTE both shells are built. kiosk gives every window a whole output with no
# configuration; lua hands surface placement, stacking and fullscreen to a
# script, so the layout can change without rebuilding anything. Which one runs
# is a line in weston.ini.
#
# NOTE no xwayland: there is no X on this system to be compatible with.

rm -rf /tmp/weston
tar -xf /sources/weston-*.tar.xz -C /tmp/
mv /tmp/weston-[0-9]* /tmp/weston
pushd /tmp/weston
mkdir build
cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      --wrap-mode=nodownload \
      -Dbackend-default=drm \
      -Dbackend-drm=true \
      -Dbackend-headless=false \
      -Dbackend-pipewire=false \
      -Dbackend-rdp=false \
      -Dbackend-vnc=false \
      -Dbackend-wayland=false \
      -Dbackend-x11=false \
      -Drenderer-gl=true \
      -Drenderer-vulkan=false \
      -Dshell-lua=true \
      -Dshell-kiosk=true \
      -Dshell-desktop=false \
      -Dshell-ivi=false \
      -Dxwayland=false \
      -Ddemo-clients=false \
      -Dtests=false \
      -Ddoc=false \
      -Dsystemd=false
ninja
ninja install
popd
rm -rf /tmp/weston

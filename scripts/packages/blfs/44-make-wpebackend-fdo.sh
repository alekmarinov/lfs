#!/bin/bash
# PACKAGE:  wpebackend-fdo
# SOURCE:   wpebackend-fdo-*.tar.xz
# RELEASE:  2
# CLASS:    extra
set -e
echo "Building BLFS-wpebackend-fdo.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 40 MB"

# wpebackend-fdo
# The freedesktop backend for libwpe: it puts WPE's output on a Wayland
# surface and feeds it Wayland input.
#
# This is the package that makes the stack Wayland-only. There is no X11
# backend - WPE's answer to X is to run under a compositor like anything else,
# and an appliance with no compositor uses cog's DRM platform instead of this.
#
# https://wpewebkit.org/
#
# BUILD_REQUIRES: 44-make-libwpe 24-make-wayland 24-make-wayland-protocols 9-make-glib 24-make-mesa 8.57-make-meson 8.56-make-ninja
# RUNTIME_REQUIRES:
#
# NOTE it needs mesa built with the wayland platform. With -Dplatforms=x11
# alone libEGL has no wayland-egl support, and this compiles but produces a
# backend that cannot create a surface at runtime - a failure that looks like
# a driver problem rather than a build option.

rm -rf /tmp/wpebackend-fdo
tar -xf /sources/wpebackend-fdo-*.tar.xz -C /tmp/
mv /tmp/wpebackend-fdo-[0-9]* /tmp/wpebackend-fdo
pushd /tmp/wpebackend-fdo

# Two null dereferences, both of which crashed cog on real hardware.
#
# The first is a buffer destroy handler which reads the resource's user data
# and immediately uses it. Upstream does check - with assert() - and we build
# --buildtype=release, which defines NDEBUG and deletes the check. The pointer
# really can be null: a resource whose user data has already been cleared is
# destroyed again during video playback, and youtube.com reproduces it every
# time. It faulted reading user_data_destroy_func at offset 0x80 of address 0.
#
# The second walks bufferResources without checking the list head was ever
# initialised. wl_list_for_each starts at list->next, and container_of
# subtracts 8 from it, so an uninitialised head faults at 0xfffffffffffffff8 -
# which is what the second crash reported, on teardown.
#
# Both are guards upstream should carry; neither changes behaviour when the
# pointers are valid. Reported as sed rather than a patch file because they
# are two lines and the surrounding code has not moved in years.
sed -i 's|\(    auto \*buffer = static_cast<struct linux_dmabuf_buffer \*>(wl_resource_get_user_data(resource));\)|\1\n    if (!buffer)\n        return;|' \
    src/linux-dmabuf/linux-dmabuf.cpp
sed -i 's|\(        BufferResource\* matchingResource = nullptr;\)|        if (!bufferResources.next)\n            return;\n\1|' \
    src/view-backend-exportable-fdo.cpp
grep -q 'if (!buffer)' src/linux-dmabuf/linux-dmabuf.cpp || { echo "the dmabuf guard did not apply"; exit 1; }
grep -q 'if (!bufferResources.next)' src/view-backend-exportable-fdo.cpp || { echo "the list guard did not apply"; exit 1; }
mkdir build
cd build
meson setup --prefix=/usr \
            --buildtype=release \
            --wrap-mode=nofallback \
            ..
ninja
ninja install
popd
rm -rf /tmp/wpebackend-fdo

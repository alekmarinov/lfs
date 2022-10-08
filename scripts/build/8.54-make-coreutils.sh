#!/bin/bash
set -e
echo "Building coreutils.."
echo "Approximate build time: 2.8 SBU"
echo "Required disk space: 159 MB"

# 8.54. Coreutils
# The Coreutils package contains utilities for showing and setting the basic system characteristics.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/coreutils.html

tar -xf /sources/coreutils-*.tar.xz -C /tmp/ \
    && mv /tmp/coreutils-* /tmp/coreutils \
    && pushd /tmp/coreutils \
    && patch -Np1 -i $(ls /sources/coreutils-*-i18n-1.patch) \
    && autoreconf -fiv \
    && FORCE_UNSAFE_CONFIGURE=1 ./configure \
        --prefix=/usr \
        --enable-no-install-program=kill,uptime \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then \
        make NON_ROOT_USERNAME=tester check-root; \
        echo "dummy:x:102:tester" >> /etc/group; \
        chown -Rv tester .; \
        su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"; \
        sed -i '/dummy/d' /etc/group; \
    fi \
    && make install \
    && mv -v /usr/bin/chroot /usr/sbin \
    && mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8 \
    && sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8 \
    && popd \
    && rm -rf /tmp/coreutils

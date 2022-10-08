#!/bin/bash
set -e
echo "Building bash.."
echo "Approximate build time:  0.5 SBU"
echo "Required disk space: 64 MB"

# 6.4. Bash
# The Bash package contains the Bourne-Again SHell.
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter06/bash.html

tar -xf bash-*.tar.gz -C /tmp/ \
    && mv /tmp/bash-* /tmp/bash \
    && pushd /tmp/bash \
    && ./configure --prefix=/usr \
        --build=$(support/config.guess) \
        --host=$LFS_TGT \
        --without-bash-malloc \
    && make \
    && make DESTDIR=$LFS install \
    && ln -sv bash $LFS/bin/sh \
    && popd \
    && rm -rf /tmp/bash

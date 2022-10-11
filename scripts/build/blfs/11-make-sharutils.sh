#!/bin/bash
set -e
echo "Building BLFS-sharutils.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 22 MB"

# 11. sharutils
# The Sharutils package contains utilities that can create 'shell' archives.
# https://www.linuxfromscratch.org/blfs/view/stable/general/sharutils.html

tar -xf /sources/sharutils-*.tar.xz -C /tmp/ \
    && mv /tmp/sharutils-* /tmp/sharutils \
    && pushd /tmp/sharutils \
    && sed -i 's/BUFSIZ/rw_base_size/' src/unshar.c \
    && sed -i '/program_name/s/^/extern /' src/*opts.h \
    && sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c \
    && echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h \
    && ./configure \
        --prefix=/usr \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check || true; fi \
    && make install \
    && popd \
    && rm -rf /tmp/sharutils

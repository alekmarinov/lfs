#!/bin/bash
set -e
echo "Building e2fsprogs.."
echo "Approximate build time: 4.4 SBU on a spinning disk, 1.2 SBU on an SSD"
echo "Required disk space: 94 MB"

# 8.74. E2fsprogs
# The e2fsprogs package contains the utilities for handling the ext2 file
# system. It also supports the ext3 and ext4 journaling file systems.
tar -xf /sources/e2fsprogs-*.tar.gz -C /tmp/ \
    && mv /tmp/e2fsprogs-* /tmp/e2fsprogs \
    && pushd /tmp/e2fsprogs \
    && mkdir -v build \
    && cd build \
    && ../configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --enable-elf-shlibs \
        --disable-libblkid \
        --disable-libuuid \
        --disable-uuidd \
        --disable-fsck \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make check; fi \
    && make install \
    && rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a \
    && gunzip -v /usr/share/info/libext2fs.info.gz \
    && install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info \
    && if [ $LFS_DOCS -eq 1 ]; then \
        makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo \
        install -v -m644 doc/com_err.info /usr/share/info \
        install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info \
    fi \
    && popd \
    && rm -rf /tmp/e2fsprogs

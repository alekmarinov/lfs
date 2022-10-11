#!/bin/bash
set -e
echo "Building BLFS-db.."
echo "Approximate build time: 0.6 SBU"
echo "Required disk space: 265 MB"

# 22. db
# The Berkeley DB package contains programs and utilities used by many
# other applications for database related functions.
# optional: libnsl,sharutils
# https://www.linuxfromscratch.org/blfs/view/stable/server/db.html

VER=$(ls /sources/db-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/db-*.tar.gz -C /tmp/ \
    && mv /tmp/db-* /tmp/db \
    && pushd /tmp/db \
    && sed -i 's/\(__atomic_compare_exchange\)/\1_db/' src/dbinc/atomic.h \
    && cd build_unix \
    && ../dist/configure \
        --prefix=/usr \
        --enable-compat185 \
        --enable-dbm \
        --disable-static \
        --enable-cxx \
    && make \
    && make docdir=/usr/share/doc/db-$VER install \
    && chown -v -R root:root \
      /usr/bin/db_* \
      /usr/include/db{,_185,_cxx}.h \
      /usr/lib/libdb*.{so,la} \
      /usr/share/doc/db-$VER \
    && popd \
    && rm -rf /tmp/db

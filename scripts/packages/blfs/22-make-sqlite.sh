#!/bin/bash
set -e
echo "Building BLFS-sqlite.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 76 MB"

# 12. sqlite
# The SQLite package is a software library that implements a self-contained, serverless, zero-configuration,
# transactional SQL database engine.
# https://www.linuxfromscratch.org/blfs/view/stable/server/sqlite.html

VER_PACK=$(ls /sources/sqlite-autoconf-*.tar.gz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
VER=${VER_PACK:0:1}.${VER_PACK:1:2}.$(echo ${VER_PACK:3:2} | bc)
tar -xf /sources/sqlite-*.tar.gz -C /tmp/ \
    && mv /tmp/sqlite-* /tmp/sqlite \
    && pushd /tmp/sqlite \
    && if [ $LFS_DOCS -eq 1 ]; then unzip -q /sources/sqlite-doc-$VER_PACK.zip; fi \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --enable-fts5 \
        CPPFLAGS="-DSQLITE_ENABLE_FTS3=1 \
                -DSQLITE_ENABLE_FTS4=1 \
                -DSQLITE_ENABLE_COLUMN_METADATA=1 \
                -DSQLITE_ENABLE_UNLOCK_NOTIFY=1 \
                -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
                -DSQLITE_SECURE_DELETE=1 \
                -DSQLITE_ENABLE_FTS3_TOKENIZER=1" \
    && make \
    && make install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        install -v -m755 -d /usr/share/doc/sqlite-$VER; \
        cp -v -R sqlite-doc-3390200/* /usr/share/doc/sqlite-$VER; \
    fi \
    && popd \
    && rm -rf /tmp/sqlite

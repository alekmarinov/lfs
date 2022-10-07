#!/bin/bash
set -e
echo "Building Expect.."
echo "Approximate build time: 0.2 SBU"
echo "Required disk space: 3.9 MB"

# 8.16. Expect
VER=$(ls /sources/expect*.tar.gz | grep -oP "expect[\d.]*" | sed 's/^expect\(.*\)\.$/\1/')
tar -xf /sources/expect*.tar.gz -C /tmp/ \
    && mv /tmp/expect* /tmp/expect \
    && pushd /tmp/expect \
    && ./configure \
        --prefix=/usr \
            --with-tcl=/usr/lib \
            --enable-shared \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make test; fi \
    && make install \
    && ln -svf expect$VER/libexpect$VER.so /usr/lib \
    && popd \
    && rm -rf /tmp/expect

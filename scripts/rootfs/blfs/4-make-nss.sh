#!/bin/bash
set -e
echo "Building BLFS-nss.."
echo "Approximate build time: 3.0 SBU"
echo "Required disk space: 332 MB"

# 4. nss
# The Network Security Services (NSS) package is a set of libraries designed
# to support cross-platform development of security-enabled client and server applications. 
# required: nspr
# recommended: sqlite,p11-kit (runtime)
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/nss.html

VER=$(ls /sources/nss-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/nss-*.tar.gz -C /tmp/ \
    && mv /tmp/nss-* /tmp/nss \
    && pushd /tmp/nss \
    && patch -Np1 -i /sources/nss-$VER-standalone-1.patch \
    && cd nss \
    && make \
        BUILD_OPT=1 \
        NSPR_INCLUDE_DIR=/usr/include/nspr \
        USE_SYSTEM_ZLIB=1 \
        ZLIB_LIBS=-lz \
        NSS_ENABLE_WERROR=0 \
        $([ $(uname -m) = x86_64 ] && echo USE_64=1) \
        $([ -f /usr/include/sqlite3.h ] && echo NSS_USE_SYSTEM_SQLITE=1) \
    && if [ $LFS_TEST -eq 1 ]; then \
        cd tests; \
        HOST=localhost DOMSUF=localdomain ./all.sh; \
        cd ../; \
    fi \
    && cd ../dist \
    && install -v -m755 Linux*/lib/*.so /usr/lib \
    && install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib \
    && install -v -m755 -d /usr/include/nss \
    && cp -v -RL {public,private}/nss/* /usr/include/nss \
    && chmod -v 644 /usr/include/nss/* \
    && install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin \
    && install -v -m644 Linux*/lib/pkgconfig/nss.pc /usr/lib/pkgconfig \
    && popd \
    && rm -rf /tmp/nss

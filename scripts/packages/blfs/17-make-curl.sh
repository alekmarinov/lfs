#!/bin/bash
set -e
echo "Building BLFS-curl.."
echo "Approximate build time: 0.4 SBU"
echo "Required disk space: 145 MB"

# 17. curl
# The cURL package contains an utility and a library used for transferring files
# with URL syntax to any of the following protocols: FTP, FTPS, HTTP, HTTPS, SCP,
# SFTP, TFTP, TELNET, DICT, LDAP, LDAPS and FILE.
# recommended: make-ca
# optional: brotli,c-ares,gnutls,libidn2,libpsl,libssh2,krb5,nghttp2,openldap,samba,gsasl,impacket,libmetalink,librtmp,ngtcp2,quiche,spnego
# https://www.linuxfromscratch.org/blfs/view/stable/basicnet/curl.html

VER=$(ls /sources/curl-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
tar -xf /sources/curl-*.tar.xz -C /tmp/ \
    && mv /tmp/curl-* /tmp/curl \
    && pushd /tmp/curl \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --with-openssl \
        --enable-threaded-resolver \
        --with-ca-path=/etc/ssl/certs \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make test || true; fi \
    && make install \
    && rm -rf docs/examples/.deps \
    && find docs \( -name Makefile\* -o -name \*.1 -o -name \*.3 \) -exec rm {} \; \
    && install -v -d -m755 /usr/share/doc/curl-$VER \
    && cp -v -R docs/* /usr/share/doc/curl-$VER \
    && popd \
    && rm -rf /tmp/curl

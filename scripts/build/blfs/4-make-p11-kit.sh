#!/bin/bash
set -e
echo "Building BLFS-p11-kit.."
echo "Approximate build time: 0.5 SBU"
echo "Required disk space: 44 MB"

# 4. p11-kit
# The p11-kit package provides a way to load and enumerate PKCS #11 (a Cryptographic Token Interface Standard) modules.
# recommended: libtasn1,make-ca (runtime)
# optional: gtk-doc,libxslt,nss (runtime)
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/p11-kit.html

tar -xf /sources/p11-kit-*.tar.xz -C /tmp/ \
    && mv /tmp/p11-kit-* /tmp/p11-kit \
    && pushd /tmp/p11-kit

sed '20,$ d' -i trust/trust-extract-compat
cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF

mkdir p11-build \
    && cd p11-build \
    && meson \
        --prefix=/usr \
        --buildtype=release \
        -Dtrust_paths=/etc/pki/anchors \
    && ninja \
    && if [ $LFS_TEST -eq 1 ]; then ninja test || true; fi \
    && ninja install \
    && ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
            /usr/bin/update-ca-certificates \
    && popd \
        && rm -rf /tmp/p11-kit

#!/bin/bash
set -e
echo "Building BLFS-make-ca.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 6.6 MB"

# 4. make-ca
# Public Key Infrastructure (PKI) is a method to validate the authenticity of 
# an otherwise unknown entity across untrusted networks. PKI works by establishing
# a chain of trust, rather than trusting each individual host or entity explicitly.
# In order for a certificate presented by a remote entity to be trusted, that certificate 
# must present a complete chain of certificates that can be validated using the root 
# certificate of a Certificate Authority (CA) that is trusted by the local machine.
# required: p11-kit
# optional: nss
# https://www.linuxfromscratch.org/blfs/view/stable/postlfs/make-ca.html

VER=$(ls /sources/make-ca-*.tar.xz | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
tar -xf /sources/make-ca-*.tar.xz -C /tmp/ \
    && mv /tmp/make-ca-* /tmp/make-ca \
    && pushd /tmp/make-ca \
    && make install \
    && install -vdm755 /etc/ssl/local \
    && popd \
    && rm -rf /tmp/make-ca

cat > /etc/cron.weekly/update-pki.sh << "EOF"
#!/bin/bash
/usr/sbin/make-ca -g
EOF
chmod 754 /etc/cron.weekly/update-pki.sh

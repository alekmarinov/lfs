#!/bin/bash
set -e
echo "Building findutils.."
echo "Approximate build time: 0.8 SBU"
echo "Required disk space: 52 MB"

# 8.58. Findutils
# The Findutils package contains programs to find files.
# These programs are provided to recursively search through a directory tree
# and to create, maintain, and search a database
tar -xf /sources/findutils-*.tar.gz -C /tmp/ \
    && mv /tmp/findutils-* /tmp/findutils \
    && pushd /tmp/findutils \
    && case $(uname -m) in \
        i?86)   TIME_T_32_BIT_OK=yes ./configure --prefix=/usr --localstatedir=/var/lib/locate ;; \
        x86_64) ./configure --prefix=/usr --localstatedir=/var/lib/locate ;; \
    esac \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then \
        chown -Rv tester . \
        su tester -c "PATH=$PATH make check" \
    fi \
    && make install \
    && popd \
    && rm -rf /tmp/findutils

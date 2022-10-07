#!/bin/bash
set -e
echo "Building bash"
echo "Approximate build time: 1.4 SBU"
echo "Required disk space: 50 MB"

# 8.34. Bash
# The Bash package contains the Bourne-Again SHell.
VER=$(ls /sources/bash-*.tar.gz | grep -oP "\-[\d.]*" | sed 's/^.\(.*\).$/\1/')
tar -xf /sources/bash-*.tar.gz -C /tmp/ \
    && mv /tmp/bash-* /tmp/bash \
    && pushd /tmp/bash \
    && ./configure \
        --prefix=/usr \
        --docdir=/usr/share/doc/bash-$VER \
        --without-bash-malloc\
        --with-installed-readline \
    && make

if [ $LFS_TEST -eq 1 ]; then
    chown -Rv tester .
    su -s /usr/bin/expect tester << EOF
        set timeout -1
        spawn make tests
        expect eof
        lassign [wait] _ _ _ value
        exit $value
    EOF
fi

make install \
    && popd \
    && rm -rf /tmp/bash

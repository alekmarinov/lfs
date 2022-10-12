#!/bin/bash
set -e
echo "Building BLFS-git.."
echo "Approximate build time: 0.3 SBU"
echo "Required disk space: 245 MB"

# 13. git
# Git is a free and open source, distributed version control system designed
# to handle everything from small to very large projects with speed and efficiency.
# recommended: curl
# optional: gnupg,openssh,pcre2,subversion,tk,valgrind,perl-io-socket-ssl
# https://www.linuxfromscratch.org/blfs/view/svn/general/git.html

VER=$(ls /sources/git-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
PERL5_VER=$(ls /sources/perl-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
PERL5_VER=${PERL5_VER%.*}
tar -xf /sources/git-*.tar.xz -C /tmp/ \
    && mv /tmp/git-* /tmp/git \
    && pushd /tmp/git \
    && ./configure \
        --prefix=/usr \
        --with-gitconfig=/etc/gitconfig \
        --with-python=python3 \
    && make \
    && if [ $LFS_TEST -eq 1 ]; then make test || true; fi \
    && make perllibdir=/usr/lib/perl5/$PERL5_VER/site_perl install \
    && if [ $LFS_DOCS -eq 1 ]; then \
        tar -xf /sources/git-manpages-$VER.tar.xz \
            -C /usr/share/man --no-same-owner --no-overwrite-dir; \
        mkdir -vp /usr/share/doc/git-$VER \
            && tar -xf /sources/git-htmldocs-$VER.tar.xz \
                -C /usr/share/doc/git-$VER --no-same-owner --no-overwrite-dir \
            && find /usr/share/doc/git-$VER -type d -exec chmod 755 {} \; \
            && find /usr/share/doc/git-$VER -type f -exec chmod 644 {} \;; \
        mkdir -vp /usr/share/doc/git-$VER/man-pages/{html,text} \
        && mv /usr/share/doc/git-$VER/{git*.txt,man-pages/text} \
        && mv /usr/share/doc/git-$VER/{git*.,index.,man-pages/}html \
        && mkdir -vp /usr/share/doc/git-$VER/technical/{html,text} \
        && mv /usr/share/doc/git-$VER/technical/{*.txt,text} \
        && mv /usr/share/doc/git-$VER/technical/{*.,}html \
        && mkdir -vp /usr/share/doc/git-$VER/howto/{html,text} \
        && mv /usr/share/doc/git-$VER/howto/{*.txt,text} \
        && mv /usr/share/doc/git-$VER/howto/{*.,}html \
        && sed -i '/^<a href=/s|howto/|&html/|' /usr/share/doc/git-$VER/howto-index.html \
        && sed -i '/^\* link:/s|howto/|&html/|' /usr/share/doc/git-$VER/howto-index.txt; \
    fi \
    && popd \
    && rm -rf /tmp/git

#!/bin/bash
set -e
echo "Building BLFS-pinentry.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 5.6 MB"

# 11. pinentry
# The PIN-Entry package contains a collection of simple PIN or pass-phrase entry 
# dialogs which utilize the Assuan protocol as described by the Ägypten project. 
# PIN-Entry programs are usually invoked by the gpg-agent daemon, but can be run
# from the command line as well. There are programs for various text-based and GUI
# environments, including interfaces designed for Ncurses (text-based), and for
# the common GTK and Qt toolkits.
# required: libassuan,libgpg-error
# optional: emacs,fltk,gcr,gtk+,libsecret,qt5,efl
# https://www.linuxfromscratch.org/blfs/view/stable/general/pinentry.html

tar -xf /sources/pinentry-*.tar.bz2 -C /tmp/ \
    && mv /tmp/pinentry-* /tmp/pinentry \
    && pushd /tmp/pinentry \
    && ./configure \
        --prefix=/usr \
        --enable-pinentry-tty \
    && make \
    && make install \
    && popd \
    && rm -rf /tmp/pinentry

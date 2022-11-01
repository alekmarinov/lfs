#!/bin/bash
set -e
echo "Stripping ..."

# 8.78. Stripping
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter08/stripping.html

save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.30
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

NCURSES_VER=$(ls /sources/ncurses-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
READLINE_VER=$(ls /sources/readline-*.tar.gz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')
READLINE_VER=${READLINE_VER%.*}
ZLIB_VER=$(ls /sources/zlib-*.tar.xz | sed 's/^[^-]*-//' | sed 's/[^0-9]*$//')

online_usrbin="bash find strip"
online_usrlib="libbfd-2.39.so
               libhistory.so.8.1
               libncursesw.so.$NCURSES_VER
               libm.so.6
               libreadline.so.$READLINE_VER
               libz.so.$ZLIB_VER
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-unneeded $i || true
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib

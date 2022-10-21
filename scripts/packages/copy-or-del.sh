#!/bin/bash
# Loop a source directory and delete entry from destination if source file 
# is special, copy to destination otherwise
set -e

SRC_DIR="$1"
DST_DIR="$2"

find -P "$SRC_DIR" | while read -r src; do
    # remove $SRC_DIR from beginning of $src
    dst=${src#"$SRC_DIR"}
    # prefix with $DST_DIR
    dst=$(echo "$DST_DIR/$dst" | sed s#//*#/#g)
    if [[ "$(file -ib $src)" = "inode/chardevice;"* ]]; then
        # remove $dst file or directory if $src is special
        rm -rfv "$dst"
    else
        # if $src is a dir, create a dir $dst
        if [ -f "$src" ] || [ -L "$src" ]; then
            # if $src is a file, copy it to $dst
            cp -fPv "$src" "$dst"
        elif [ -d "$src" ]; then
            mkdir -pv "$dst"
        else
            echo "Unexpected file type $(file -ib $src) of $src"
            exit 1
        fi
    fi
done

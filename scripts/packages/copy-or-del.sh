#!/bin/bash
# Copy files from source to destination directory
# delete entry from destination if the source file is special
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
        rm -rf "$dst"
    else
        # if $src is a file or link, copy it to $dst
        if [ -f "$src" ] || [ -L "$src" ]; then
            cp -fP "$src" "$dst"
        # if $src is a dir, create a dir $dst
        elif [ -d "$src" ]; then
            mkdir -p "$dst"
        else
            echo "Unexpected file type $(file -ib $src) of $src"
            exit 1
        fi
    fi
done

#!/bin/bash
# Loop a source directory and delete entry from destination if source file 
# is special, copy to destination otherwise

SRC_DIR="$1"
DST_DIR="$2"

for src in `find "$SRC_DIR"`; do
    # remove $SRC_DIR from beginning of $srcfile
    dst=${src#"$SRC_DIR"}
    # prefix with $DST_DIR
    dst=$(echo "$DST_DIR/$dst" | sed s#//*#/#g)
    if [[ "$(file -ib $src)" = "inode/chardevice;"* ]]; then
        # remove $dst file or directory if $src is special
        rm -rf "$dst"
    else
        # if $src is a dir, create a dir $dst
        if [ -d "$src" ]; then
            mkdir -p "$dst"
        elif [ -f "$src" ]; then
            # if $src is a file, copy it to $dst
            cp -f "$src" "$dst"
        else
            echo "Unknown file type $src"
            file "$src"
        fi
    fi
done

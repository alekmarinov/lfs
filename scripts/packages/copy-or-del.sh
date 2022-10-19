#!/bin/bash
# Loop a source directory and delete entry from destination if source file 
# is special, copy to destination otherwise

SRC_DIR="$1"
DST_DIR="$2"

for srcfile in `find "$SRC_DIR"`; do
    file=${srcfile#$SRC_DIR}
    [[ "$(file -ib $srcfile)" = "inode/chardevice;"* ]] \
        && rm -rf "$DST_DIR/$file" \
        || cp -rf $srcfile "$DST_DIR"/
done

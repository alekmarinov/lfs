#!/bin/bash
# Finds which package provides a file
set -e

PACKAGES="packages"
file="$1"

if [ "$file" == "" ]; then
    echo "Missing argument: file"
    exit 1
fi

for package in $(ls $PACKAGES/*.tar.gz); do
    
    tar -ztvf "$package" | awk '{ print $6 }' \
        | grep "$file" \
        | while read -r fullpath;
    do
        filename=$(basename "$fullpath")
        if [ "$filename" == "$file" ]; then
            echo "$package" "$fullpath"
        fi
    done
done

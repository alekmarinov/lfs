#!/bin/bash
set -E

force_build=0
script_path=""
while [[ $# -gt 0 ]]; do
    case $1 in
    -f|--force)
        force_build=1
        shift
        ;;
    -*|--*)
        echo "Unknown option $1"
        exit 1
        ;;
    *)
        if [[ "$script_path" != "" ]]; then
            echo "Only one positional argument expected: script_path"
            exit 1
        fi
        script_path="$1"
        shift
        ;;
    esac
done
if [ $script_path == "" ]; then
    echo "Missing argument: script_path"
    exit 1
fi

script_name=$(basename -- "$script_path")
flag_file="/tmp/${script_name%.*}.ready"
log_file="/tmp/${script_name%.*}.log"
if [[ ! -f "$flag_file" || $force_build -eq 1 ]]; then
    echo -ne "...... $script_path -> $log_file"
    sh "$script_path" > "$log_file" 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "\rpassed"; echo
        touch "$flag_file"
    else
        echo -ne "\rfailed"; echo
    fi
else
    echo "skipped $script_path"
fi

#!/bin/bash
set +e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

script_path="$1"
if [ "$script_path" == "" ]; then
    echo "Missing argument: script_path"
    exit 1
fi
script_name=$(basename -- "$script_path")

log_file="/tmp/${script_name%.*}.log"
if [ ! -f "$script_path" ]; then
    echo -ne "\r\nbuild.sh: Can't find script $script_path"
    exit 1
fi
export PATH+=:$LFS_BASE/tools/bin
echo -ne "...... $script_path -> $log_file"
if "$script_path" > "$log_file" 2>&1; then
    echo -ne "\rpassed"; echo
else
    echo -ne "\rfailed"; echo
    tail "$log_file"
    echo
    # Exit with failure
    exit 1
fi

#!/bin/bash
set +e

__NAME__=$(basename "$0")

script_path="$1"
if [ "$script_path" == "" ]; then
    echo "Missing argument: script_path"
    exit 1
fi
script_name=$(basename -- "$script_path")

# under $LFS_BASE, not /tmp: /tmp is the container's own and disappears with
# it, taking the log of whatever just failed
log_file="$LFS_BASE/tmp/${script_name%.*}.log"
if [ ! -f "$script_path" ]; then
    echo -ne "\r\n$__NAME__: Can't find script $script_path"
    exit 1
fi
export PATH+=:$LFS_BASE/tools/bin

# A stage which has already succeeded is not repeated. Without this every
# retry rebuilds gcc from scratch before reaching the stage which actually
# failed, which is forty minutes an iteration. Same idea as the .ready flags
# the package builds use. Set TOOLS_FORCE=1 to build a stage again anyway.
flag_file="$LFS_BASE/tmp/${script_name%.*}.ready"
mkdir -p "$LFS_BASE/tmp"
if [ -f "$flag_file" ] && [ "${TOOLS_FORCE:-0}" != "1" ]; then
    echo "skip   $script_path"
    exit 0
fi

echo -ne "...... $script_path -> $log_file"
if "$script_path" > "$log_file" 2>&1; then
    touch "$flag_file"
    echo -ne "\rpassed"; echo
else
    echo -ne "\rfailed"; echo
    tail "$log_file"
    echo
    # Exit with failure
    exit 1
fi

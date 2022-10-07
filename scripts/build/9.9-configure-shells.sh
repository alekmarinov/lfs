#!/bin/bash
set -e
echo "Setup bash shell.."

# 9.9. Creating the /etc/shells File
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter09/etcshells.html

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

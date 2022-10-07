#!/bin/bash
set -e
echo "Setup bash shell.."

# 9.7. The Bash Shell Startup Files
# https://www.linuxfromscratch.org/lfs/view/11.2/chapter09/profile.html

cat > /etc/profile << "EOF"
# Begin /etc/profile

export LANG=en_US.UTF-8

# End /etc/profile
EOF

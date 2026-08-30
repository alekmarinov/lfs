#!/bin/bash
set -e
echo "Building BLFS-nodejs.."

# nodejs
# Firefox runs javascript at build time to generate parts of itself, so node
# is required to compile it. Build only - it is in no distro.
#
# openssl and zlib are taken from the system rather than the copies bundled in
# the node source, which are another two libraries to keep patched otherwise.
# https://www.linuxfromscratch.org/blfs/view/11.2/general/nodejs.html
#
# NOTE node 16 checks the python version against a fixed list that ends at
# 3.10 and refuses to configure with the 3.13 that LFS 12.4 installs. The list
# is widened rather than a second python being installed alongside.
#
# Python 3.13 also removed the pipes module, which node's build scripts
# import. They only ever call pipes.quote(), and shlex.quote() is the same
# function, so the import is aliased rather than every call site rewritten.
#
# BUILD_REQUIRES: 7.10-make-python 8.29-make-gcc 8.69-make-make
# RUNTIME_REQUIRES:
# BUILD_ONLY: firefox runs javascript at build time to generate sources; nothing here runs node
#
# NOTE the commands are written one per line rather than chained with &&: a
# failing && chain does not trip 'set -e', so a chain followed by more commands
# reports success even though the build failed.

rm -rf /tmp/nodejs
tar -xf /sources/node-v*.tar.xz -C /tmp/
mv /tmp/node-v* /tmp/nodejs
pushd /tmp/nodejs
# uint64_t and friends used to arrive through other libstdc++ headers and no
# longer do, so node's own headers fail to parse. Forcing cstdint in covers
# every file at once.
export CXXFLAGS="-include cstdint${CXXFLAGS:+ $CXXFLAGS}"

sed -i 's/^acceptable_pythons = ((3, 10)/acceptable_pythons = ((3, 13), (3, 12), (3, 11), (3, 10)/' configure
grep -rl '^import pipes$' --include='*.py' . \
    | xargs sed -i 's/^import pipes$/import shlex as pipes/'
./configure --prefix=/usr --shared-openssl --shared-zlib
make
make install
popd
rm -rf /tmp/nodejs

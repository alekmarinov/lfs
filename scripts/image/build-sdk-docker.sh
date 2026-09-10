#!/bin/bash
# Archives the build base as a docker image: an SDK for building packages
# against this exact LFS tree, without touching this tree.
#
#   build-sdk-docker.sh <tag>
#
# WHY THIS EXISTS
#
# Building a package here means overlay-mounting $LFS_BASE under $LFS and
# working inside it. There is one $LFS, and build-package.sh refuses to stack
# a second overlay on it - correctly, because stacked overlays silently mix
# layers. The consequence is that everything serialises on one mount point:
# while LFS itself is being developed, no other project can build a package,
# and vice versa.
#
# Docker removes the contention without changing the model, because it is the
# same model. A container started from this image has the base as its lower
# layer and its own writable layer on top - which is exactly what the overlay
# gives build-package.sh, and 'docker diff' enumerates it the way the upper
# directory does. Any number of them run at once, on any machine, with no
# mount and no root on the host.
#
# WHAT IS LEFT OUT
#
# The sources tree, the docs and the man pages - 2.7 GB that no compile reads.
# Everything a build actually touches stays: headers, static archives,
# pkg-config files and the whole toolchain.
#
# WHAT IS ADDED
#
# The metadata helpers and the packer, so a package built in here can describe
# itself the same way one built by build-package.sh does - and be turned into
# a package by the same code, rather than by each consumer's own version of
# it. Without them an external project can compile but cannot produce a .lpkg
# the channel would accept.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

tag="${1:-}"
[ -n "$tag" ] || { echo "usage: make sdk-docker TAG=<tag>"; exit 1; }

LFS_BASE="${LFS_BASE:-overlay/base}"
[ -d "$LFS_BASE" ] || { echo "No build base at '$LFS_BASE' - run 'make packages' first"; exit 1; }
[ -x "$LFS_BASE/usr/bin/gcc" ] || { echo "'$LFS_BASE' has no compiler; it is not a build base"; exit 1; }

command -v docker > /dev/null || { echo "docker is not installed"; exit 1; }

# The identity of the tree this SDK is a copy of.
#
# This is the whole point of labelling: a package compiled in here is only
# installable on a system whose core matches, and the ABI id is what says so.
# build-package.sh stamps 'abi=' into every package it builds; anything built
# in this image has to stamp the same value or it cannot be checked at all.
ABI=$("$BASE_DIR/scripts/packages/abi-id.sh" 2>/dev/null || true)
[ -n "$ABI" ] || { echo "cannot compute the ABI id - run 'make packages-meta' first"; exit 1; }
[ -z "${LFS_VER:-}" ] && [ -f .env ] && LFS_VER=$(sed -n 's/^LFS_VER=//p' .env | tail -1)
[ -z "${BLFS_VER:-}" ] && [ -f .env ] && BLFS_VER=$(sed -n 's/^BLFS_VER=//p' .env | tail -1)
: "${BLFS_VER:=$LFS_VER}"
CHANNEL="lfs${LFS_VER}-blfs${BLFS_VER}"

echo "Archiving the build base as lfs-sdk:$tag"
echo "  ABI      $ABI"
echo "  channel  $CHANNEL"

# The helpers are staged into a scratch tree and appended to the tar, rather
# than written into $LFS_BASE - the base is an input to every build here and
# must not gain files because an SDK was made from it.
STAGE=$(mktemp -d); trap 'sudo rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/usr/lib/lpkg" "$STAGE/etc/lpkg"
cp "$BASE_DIR/scripts/packages/pkg-elf.sh"      "$STAGE/usr/lib/lpkg/"
cp "$BASE_DIR/scripts/packages/pkg-header.sh"   "$STAGE/usr/lib/lpkg/"
# The packer itself. pack.sh sources the two above from /usr/lib/lpkg and
# reads ABI_ID from /etc/lfs-sdk, so it only runs in here - which is the
# point: an external project mounts its work into a container and calls this,
# rather than writing its own idea of what a package looks like.
cp "$BASE_DIR/scripts/packages/pkg-pack.sh"     "$STAGE/usr/lib/lpkg/"
cp "$BASE_DIR/scripts/packages/file-policy.conf" "$STAGE/etc/lpkg/"
cat > "$STAGE/etc/lfs-sdk" <<EOF
ABI_ID=$ABI
CHANNEL=$CHANNEL
LFS=$LFS_VER
BLFS=$BLFS_VER
BUILT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

{ sudo tar -C "$LFS_BASE" -c \
        --exclude='./sources' \
        --exclude='./tmp/*' \
        --exclude='./usr/share/doc' \
        --exclude='./usr/share/man' \
        --exclude='./scripts' \
        . ; } \
    | sudo docker import \
        -c "LABEL org.opencontainers.image.title=\"LFS build SDK\"" \
        -c "LABEL org.intelibo.lfs.abi=\"$ABI\"" \
        -c "LABEL org.intelibo.lfs.channel=\"$CHANNEL\"" \
        -c "LABEL org.intelibo.lfs.lfs=\"$LFS_VER\"" \
        -c "LABEL org.intelibo.lfs.blfs=\"$BLFS_VER\"" \
        -c 'ENV PATH=/usr/bin:/usr/sbin:/bin:/sbin' \
        -c 'WORKDIR /build' \
        -c 'CMD ["/bin/bash"]' \
        - "lfs-sdk:$tag" > /dev/null

# the helpers go on as a second layer, so the base tar stays a faithful copy
sudo docker build -q -t "lfs-sdk:$tag" -f - "$STAGE" > /dev/null <<EOF
FROM lfs-sdk:$tag
COPY . /
EOF

echo
echo "Built lfs-sdk:$tag"
sudo docker images --format '  {{.Repository}}:{{.Tag}}  {{.Size}}' "lfs-sdk:$tag"
echo
echo "An external project builds against it with, for example:"
echo "    docker run --rm -v \$PWD:/build lfs-sdk:$tag \\"
echo "        bash -c 'cd /build && ./configure --prefix=/usr && make && make install'"
echo
echo "and the container's own diff is what that build installed - the same"
echo "thing the overlay upper layer is to build-package.sh."

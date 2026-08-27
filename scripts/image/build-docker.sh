#!/bin/bash
# Archives the assembled rootfs as a docker image named after the distro
set -e

ROOTFS_DIR="rootfs"
tag=$1

[ -d "$ROOTFS_DIR" ] || { echo "Directory '$ROOTFS_DIR' is missing, run 'make distro DISTRO=...' first"; exit 1; }
[ -f "$ROOTFS_DIR/etc/os-release" ] || { echo "'$ROOTFS_DIR' holds no distro, /etc/os-release is missing"; exit 1; }

if [[ "$tag" == "" ]]; then
    echo "Missing expected argument tag, use 'make docker TAG=...'"
    exit 1
fi

# identity of the assembled distro
ID=$(sed -n 's/^ID=//p' "$ROOTFS_DIR/etc/os-release")
PRETTY_NAME=$(sed -n 's/^PRETTY_NAME="\(.*\)"/\1/p' "$ROOTFS_DIR/etc/os-release")
VERSION=$(sed -n 's/^VERSION_ID=//p' "$ROOTFS_DIR/etc/os-release")
DISTRO=$(sed -n 's/^DISTRO=//p' "$ROOTFS_DIR/etc/lfs-distro" 2>/dev/null)

# refuse to label the image as a distro other than the assembled one
if [[ "$EXPECT_DISTRO" != "" && "$DISTRO" != "" && "$EXPECT_DISTRO" != "$DISTRO" ]]; then
    echo "'$ROOTFS_DIR' holds the distro '$DISTRO', not '$EXPECT_DISTRO'.
Assemble it with 'make distro DISTRO=$EXPECT_DISTRO' or archive it as '$DISTRO'."
    exit 1
fi

echo "Archiving '$PRETTY_NAME' as the docker image $ID:$tag..."

sudo tar -C "$ROOTFS_DIR" -c . \
    | sudo docker import \
        -c "LABEL org.opencontainers.image.title=\"$PRETTY_NAME\"" \
        -c "LABEL org.opencontainers.image.version=\"$VERSION\"" \
        -c "LABEL org.opencontainers.image.revision=\"$tag\"" \
        -c "ENV PATH=/usr/bin:/usr/sbin" \
        -c 'CMD ["/bin/bash"]' \
        - "$ID:$tag"

echo "
Archived $ID:$tag, try it with

    sudo docker run --rm -it $ID:$tag
"

#!/bin/bash
# Assembles the rootfs of a distro from the packages produced by the build.
#
# The distro is described by a directory under distros/:
#   distro.conf     identity, used to generate the /etc identification files
#   packages.list   the packages to install on top of the core, in build order
#   files/          copied over the assembled tree, overriding everything else
#
# distros/core/files/ is applied before the distro files, for what every
# distro needs whatever packages it picks.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )

distro=$1
if [[ "$distro" == "" ]]; then
    echo "Missing expected argument distro"
    exit 1
fi

DISTRO_DIR="$BASE_DIR/distros/$distro"
CORE_DIR="$BASE_DIR/distros/core"
ROOTFS_DIR="rootfs"

[ -d packages ] || { echo "Directory 'packages' is missing, run 'make packages' first"; exit 1; }
[ -d "$DISTRO_DIR" ] || { echo "Unknown distro '$distro', expected $DISTRO_DIR"; exit 1; }
[ -f "$DISTRO_DIR/packages.list" ] || { echo "Missing $DISTRO_DIR/packages.list"; exit 1; }
[ -f "$DISTRO_DIR/distro.conf" ] || { echo "Missing $DISTRO_DIR/distro.conf"; exit 1; }

# Only one distro is worked on at a time. The existing rootfs is overwritten
# only on demand, so that a distro which was not archived yet is not lost.
if [ -d "$ROOTFS_DIR" ] && [ "$FORCE" != "1" ]; then
    current=$(sed -n 's/^PRETTY_NAME="\(.*\)"/\1/p' "$ROOTFS_DIR/etc/os-release" 2>/dev/null)
    echo "Directory '$ROOTFS_DIR' already holds ${current:-an unknown distro}.
Archive it with 'make docker TAG=...' or discard it with 'make distro DISTRO=$distro FORCE=1'"
    exit 1
fi

# identity of the distro, STRIP given on the command line wins over distro.conf
strip_override=$STRIP
. "$DISTRO_DIR/distro.conf"
STRIP=${strip_override:-${STRIP:-0}}

# the packages a list names, without the comments and the empty lines
read_pkglist() {
    sed 's/#.*//' "$1" | tr -d '[:blank:]' | grep -v '^$'
}

# The order the packages were built in, which is the order build-packages.sh
# names them. A package rebuilt later, like freetype, keeps its last position.
build_order() {
    grep -vE '^[[:space:]]*#' "$BASE_DIR/scripts/packages/build-packages.sh" \
        | grep -oE '/scripts/packages/(lfs|blfs)/[^ ]+\.sh' \
        | sed 's|.*/||; s|\.sh$|.tar.gz|' \
        | nl -ba | tac | awk '!seen[$2]++' | tac | awk '{print $2}'
}

# install the given packages, one per line
install_packages() {
    local package
    while read -r package; do
        case "$package" in '') continue ;; esac
        [ -f "packages/$package" ] || { echo "Missing package packages/$package"; exit 1; }
        sudo tar xpf "packages/$package" -C "$ROOTFS_DIR" < /dev/null
    done
}

sudo rm -rf "$ROOTFS_DIR"
mkdir -v "$ROOTFS_DIR"

# The core and the distro packages are installed together, in the order they
# were built, rather than the core first and the distro second.
#
# Several packages write the same file - /etc/passwd is the one that matters,
# every package adding a service user carries the whole file as it looked when
# that package was built. The package built last holds the most complete copy,
# so it has to be the one unpacked last, whichever list happens to name it.
wanted=$( { read_pkglist "$CORE_DIR/packages.list"
            read_pkglist "$DISTRO_DIR/packages.list"; } | sort -u )

# a package which build-packages.sh does not build has no place in the order,
# it is installed first so that a built package can still override it
unknown=$(printf '%s\n' "$wanted" | grep -vxF -f <(build_order) || true)
if [ -n "$unknown" ]; then
    echo "Installing the packages which are not built by build-packages.sh..."
    printf '%s\n' "$unknown" | sed 's/^/  /'
    printf '%s\n' "$unknown" | install_packages
fi

echo "Installing the core and the $distro packages in build order..."
build_order | grep -xF -f <(printf '%s\n' "$wanted") | install_packages

# A package removing a file carries it as a 0:0 character device, the whiteout
# overlayfs left behind. Once every package is unpacked, a whiteout which was
# not overwritten by a later package means the file is deleted.
echo "Applying the deleted files..."
sudo find "$ROOTFS_DIR" -type c 2>/dev/null | while read -r path; do
    # a whiteout is the 0:0 device, anything else is a real device node
    if [ "$(sudo stat -c '%t %T' "$path")" = "0 0" ]; then
        sudo rm -f "$path"
        echo "  removed ${path#$ROOTFS_DIR}"
    fi
done

# The following is created by the tools build (chapters 4 and 6) directly in
# $LFS_BASE, so it is part of no package and has to be recreated here.
echo "Creating the top level directory layout..."
for i in bin lib sbin; do
    sudo ln -sfn usr/$i "$ROOTFS_DIR/$i"
done
sudo mkdir -p "$ROOTFS_DIR/lib64"
sudo ln -sfn ../lib/ld-linux-x86-64.so.2 "$ROOTFS_DIR/lib64/ld-linux-x86-64.so.2"
sudo ln -sfn ../lib/ld-linux-x86-64.so.2 "$ROOTFS_DIR/lib64/ld-lsb-x86-64.so.3"
# without /bin/sh the bootscripts stop at the first '#!/bin/sh' line
sudo ln -sfn bash "$ROOTFS_DIR/usr/bin/sh"

echo "Writing the identification files..."
BUILD_ID=$(date +%Y%m%d%H%M%S)
sudo tee "$ROOTFS_DIR/etc/os-release" > /dev/null <<EOF
NAME="$NAME"
ID=$ID
VERSION="$VERSION"
VERSION_ID=$VERSION
PRETTY_NAME="$PRETTY_NAME"
BUILD_ID=$BUILD_ID
HOME_URL="$HOME_URL"
EOF

sudo tee "$ROOTFS_DIR/etc/lsb-release" > /dev/null <<EOF
DISTRIB_ID="$NAME"
DISTRIB_RELEASE="$VERSION"
DISTRIB_CODENAME="$CODENAME"
DISTRIB_DESCRIPTION="$PRETTY_NAME"
EOF

# the release file LFS installs is named after the distro
if [ "$ID" != "lfs" ]; then
    sudo rm -f "$ROOTFS_DIR/etc/lfs-release"
fi
echo "$VERSION" | sudo tee "$ROOTFS_DIR/etc/$ID-release" > /dev/null

echo "$DISTRO_HOSTNAME" | sudo tee "$ROOTFS_DIR/etc/hostname" > /dev/null

# shadow installs /etc/shadow with a locked root account, so the password is set
# here, from the distro or from .env, to make the login prompt usable
password=${ROOT_PASSWORD:-$LFS_ROOT_PASSWORD}
if [[ "$password" != "" ]]; then
    echo "Setting the root password..."
    # a crypt hash never contains '|', so it is a safe sed delimiter here
    hash=$(openssl passwd -6 "$password")
    sudo sed -i "s|^root:[^:]*:|root:$hash:|" "$ROOTFS_DIR/etc/shadow"
else
    echo "Neither ROOT_PASSWORD nor LFS_ROOT_PASSWORD is set, the root account stays locked.
Boot with 'init=/bin/bash' appended to the kernel command line to get a shell."
fi

# The core files come first: they hold what every distro needs regardless of
# which packages it picks, such as the module blacklists for hardware quirks.
# The distro files are applied after, so a distro can override any of them.
if [ -d "$CORE_DIR/files" ]; then
    echo "Applying the core files..."
    sudo cp -a "$CORE_DIR/files/." "$ROOTFS_DIR/"
fi

# the files of the distro override the packages and the generated files
if [ -d "$DISTRO_DIR/files" ]; then
    echo "Applying the $distro files..."
    sudo cp -a "$DISTRO_DIR/files/." "$ROOTFS_DIR/"
fi

# how this rootfs was assembled
sudo tee "$ROOTFS_DIR/etc/lfs-distro" > /dev/null <<EOF
DISTRO=$distro
BUILD_ID=$BUILD_ID
BUILD_DATE="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
PACKAGES=$(cat "$CORE_DIR/packages.list" "$DISTRO_DIR/packages.list" | grep -cvE '^\s*#|^\s*$')
STRIPPED=$([ "$STRIP" = "1" ] && echo yes || echo no)
EOF

# drop the build logs the packages carry in /tmp
sudo rm -rf "$ROOTFS_DIR"/tmp/*.log

# Removing the debug symbols is the last step, so that what is checked, booted
# and archived is what ships.
#
# The book does this from inside the running system (8.78. Stripping) where a
# mapped library or a running program can not be overwritten, hence its copy to
# /tmp and its --only-keep-debug dance. Here the tree is passive, nothing in it
# is executing, so a plain walk with the host strip is enough.
if [ "$STRIP" = "1" ]; then
    echo "Stripping the debug symbols..."
    before=$(sudo du -sk "$ROOTFS_DIR" | cut -f1)
    dirs=()
    for d in bin sbin libexec lib; do
        [ -d "$ROOTFS_DIR/usr/$d" ] && dirs+=("$ROOTFS_DIR/usr/$d")
    done
    # the grub modules keep the symbols grub resolves them by, stripping them
    # leaves a boot loader which drops to the rescue shell
    sudo find "${dirs[@]}" -type f ! -path '*/usr/lib/grub/*' -print0 2>/dev/null \
        | sudo xargs -0 -r -P "$(nproc)" -n 32 sh -c '
            for f in "$@"; do
                case "$f" in
                    # a static library keeps the symbols it is linked against,
                    # a kernel module the ones it is resolved against
                    *.a|*.ko) strip --strip-debug "$f" 2>/dev/null ;;
                    # anything which is not an ELF file is simply refused
                    *)        strip --strip-unneeded "$f" 2>/dev/null ;;
                esac
            done
            true' sh
    after=$(sudo du -sk "$ROOTFS_DIR" | cut -f1)
    echo "    $((before / 1024)) MB -> $((after / 1024)) MB, $(( (before - after) / 1024 )) MB of symbols removed"
fi

echo "
The rootfs of '$distro' is assembled in '$ROOTFS_DIR':

$(sed 's/^/    /' "$ROOTFS_DIR/etc/lfs-distro")

Check it with 'make check', archive it with 'make docker TAG=...'
or turn it into a bootable image with 'make image'.
"

#!/bin/bash
set -e

# LFS and BLFS are separate books with separate version numbers, so the two
# lists are named independently. BLFS_VER defaults to LFS_VER when unset.
: "${LFS_VER:?LFS_VER is not set}"
: "${BLFS_VER:=$LFS_VER}"

pushd $LFS_BASE/sources

WGET_OPTS="--no-check-certificate --timestamping -c --timeout=30 --tries=5 --report-speed=bits"

# Mirrors holding the complete LFS package set. They are tried for the packages
# which can't be fetched from their upstream location.
FALLBACK_MIRRORS="\
https://ftp.osuosl.org/pub/lfs/lfs-packages/${LFS_VER:-12.4} \
https://anduin.linuxfromscratch.org/LFS \
https://anduin.linuxfromscratch.org/BLFS"

# ftp.gnu.org starts refusing connections after a while when the whole package
# set is pulled from it, so the same path is retried on the GNU mirrors.
GNU_MIRRORS="\
https://mirrors.kernel.org/gnu \
https://ftp.wayne.edu/gnu \
https://mirror.us-midwest-1.nexcess.net/gnu"

# List the packages of the given md5sums file which are missing or corrupted
list_broken() {
    md5sum -c "$1" 2>/dev/null | grep -v ': OK$' | cut -d: -f1
}

# Print the alternative urls to try for a package
# alternative_urls <package file name> <wget list>
alternative_urls() {
    local file="$1" wget_list="$2" url mirror

    # the upstream url of this package, if it is a GNU one retry it on the
    # GNU mirrors keeping the path
    url=$(grep -m1 -E "/${file//./\\.}\$" "$wget_list" || true)
    case "$url" in
    */ftp.gnu.org/gnu/*)
        for mirror in $GNU_MIRRORS; do
            echo "$mirror/${url#*/ftp.gnu.org/gnu/}"
        done
        ;;
    esac

    for mirror in $FALLBACK_MIRRORS; do
        echo "$mirror/$file"
    done
}

# download <md5sums file> <wget list> <name>
download() {
    local md5sums="$1" wget_list="$2" name="$3" broken file url

    echo "Checking MD5 sum of the $name packages.."
    if md5sum -c "$md5sums"; then
        return 0
    fi

    echo "Downloading $name packages.."
    wget $WGET_OPTS --input-file="$wget_list" \
        || echo "Some $name packages failed to download from their upstream location"

    # Retry the packages which are still missing or corrupted from the mirrors
    broken=$(list_broken "$md5sums")
    for file in $broken; do
        for url in $(alternative_urls "$file" "$wget_list"); do
            echo "Retrying $file from $url .."
            # a partially downloaded file must not be continued from a mirror
            rm -f "$file"
            if wget $WGET_OPTS "$url"; then
                break
            fi
        done
    done

    echo "Checking MD5 sum of the $name packages.."
    md5sum -c "$md5sums"
}

# Some files have to be fetched from a url whose last path component is not the
# name the file has to be saved under - a firmware blob pinned to a tag carries
# the tag in a query string, and wget --input-file has no way to rename what it
# downloads. Those are listed separately as '<filename> <url>' and fetched one
# at a time with -O.
download_extra() {
    local list="$1" name="$2" file url
    [ -f "$list" ] || return 0
    echo "Checking the individually named $name files.."
    while read -r file url; do
        case "$file" in ''|'#'*) continue ;; esac
        if [ -f "$file" ]; then continue; fi
        echo "Downloading $file .."
        # firmware names carry the directory they are installed under
        mkdir -p "$(dirname "$file")"
        wget $WGET_OPTS -O "$file" "$url" || rm -f "$file"
    done < "$list"
}

download "lfs-$LFS_VER.md5sums"  "lfs-$LFS_VER.wget-list"  LFS
download_extra "blfs-$BLFS_VER.extra-list" BLFS
download "blfs-$BLFS_VER.md5sums" "blfs-$BLFS_VER.wget-list" BLFS

popd

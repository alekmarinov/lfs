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

# A distro is either one of ours, named, or anyone's, given as a path - see
# scripts/resolve-distro.sh, which build-distro-packages.sh also uses.
DISTRO_DIR=$("$BASE_DIR/scripts/resolve-distro.sh" "$distro")
CORE_DIR="$BASE_DIR/distros/core"

# Where this distro's rootfs and image are written. One directory per distro,
# so two can be assembled side by side, and $OUT so a client can put its own
# somewhere else entirely - which is the expected case, because an output
# directory named after somebody else's distro has no business in here.
OUT=$("$BASE_DIR/scripts/resolve-distro.sh" -o "$distro")
ROOTFS_DIR="$OUT/rootfs"
mkdir -p "$OUT"

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

# ID names the distro everywhere it is written down: /etc/os-release, the
# release file, the output directory. It used to be able to go missing - an
# unset ID wrote 'ID=' into os-release and created a file called /etc/-release
# - which was invisible until the output directory was named after it. It is
# required now, and checked here rather than discovered later.
case "$ID" in
    "")       echo "$DISTRO_DIR/distro.conf sets no ID. It names the distro in"
              echo "/etc/os-release, /etc/<ID>-release and the output directory."
              exit 1 ;;
    *[!a-zA-Z0-9._-]*)
              echo "ID '$ID' in $DISTRO_DIR/distro.conf: letters, digits, dot,"
              echo "dash and underscore only - it is used as a directory name."
              exit 1 ;;
esac

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

    # then the recipes the distro brings of its own, last and in the order
    # build-distro-packages.sh built them.
    #
    # Without this they are not unknown to the installer - they are worse than
    # unknown. Anything in packages.list which build_order does not name falls
    # into the 'unknown' bucket below and is installed *first*, before the core
    # and before everything it was built against, reported as a note rather
    # than an error. A distro's own packages depend on what the book builds, so
    # first is exactly wrong and would have worked only by luck.
    #
    # Their names are the distro's business: the x- prefix marks a package the
    # LFS book does not cover and belongs to this repository's own tree, not to
    # somebody else's directory.
    if [ -d "$DISTRO_DIR/packages" ]; then
        ( cd "$DISTRO_DIR/packages" && ls *.sh 2>/dev/null | sort | sed 's|\.sh$|.tar.gz|' )
    fi
}

# install the given packages, one per line
# /etc/passwd and the files which go with it are not owned by any one package:
# every package which adds a service account writes the whole file, holding the
# accounts which existed when it was built plus its own. Unpacking them in
# order therefore keeps only the last one written, and every account added
# before it is lost - which is how a distro ends up booting with "no such user
# dhcpcd" and "privilege separation user sshd does not exist" while both
# packages are installed.
#
# They are merged instead: the copy just unpacked is kept as it stands, and any
# account the previous state had which it does not mention is appended. The key
# is the first field, so passwd, group, shadow and gshadow stay in step.
#
# NOTE this cannot express a deletion. A package which removes an account -
# 8.85-clean removes the tester account the test suites use - writes a file
# which simply lacks it, and that is indistinguishable from a file written
# before the account existed. Such a removal has to be repeated below.
install_packages() {
    local package f b
    while read -r package; do
        case "$package" in '') continue ;; esac
        [ -f "packages/$package" ] || { echo "Missing package packages/$package"; exit 1; }
        snapshot_merge_paths
        # .meta is the record of which files this package created and which
        # it changed. It describes the package, it is not part of the distro,
        # and without excluding it every package drops its lists into the
        # root of the image.
        # -v, so the list of what this package put into the tree is recorded
        # as it goes. An assembled rootfs has to arrive with a package database
        # or the first 'lpkg upgrade' on it sees a system where nothing is
        # installed: it can upgrade none of it, and anything it does install
        # claims files it does not own.
        #
        # Taken from the extraction rather than from .meta/created, because
        # this is complete for every package regardless of age - the packages
        # built before the file lists included symlinks have an incomplete
        # .meta, and tar has no such gap.
        sudo tar xpvf "packages/$package" -C "$ROOTFS_DIR" \
            --exclude="./.meta" --exclude="./.meta/*" < /dev/null \
            > "$MERGE_WORK/extracted" 2>/dev/null
        seed_db_entry "$package" "$MERGE_WORK/extracted"
        apply_merges
        sudo rm -f "$MERGE_WORK"/*
    done
}

# ------------------------------------------------------------ package database
#
# One directory per installed package under /var/lib/lpkg/db, filled from the
# metadata index which 'make packages-meta' already built, plus the list of
# paths this extraction actually wrote. 'owners' is derived from all of them at
# the end.
LPKG_DB="$ROOTFS_DIR/var/lib/lpkg"

seed_db_entry() {
    local package="$1" extracted="$2"
    local recipe="${package%.tar.gz}"
    local meta="$BASE_DIR/packages/.meta-index/$recipe"
    local name

    if [ -f "$meta/PKGINFO" ]; then
        name=$(sed -n 's/^name=//p' "$meta/PKGINFO")
    else
        # No identity for it - see 'make packages-meta'. Recorded under the
        # recipe coordinate so the file is still owned by something, rather
        # than left out of the database and looking unowned.
        name="$recipe"
    fi
    [ -n "$name" ] || return 0

    local d="$LPKG_DB/db/$name"
    sudo mkdir -p "$d"
    if [ -f "$meta/PKGINFO" ]; then
        sudo cp "$meta/PKGINFO" "$d/PKGINFO"
    else
        printf 'name=%s\nversion=0\nrelease=0\nclass=extra\nrecipe=%s\n' \
            "$name" "$recipe" | sudo tee "$d/PKGINFO" > /dev/null
    fi
    [ -f "$meta/provides" ] && sudo cp "$meta/provides" "$d/provides"
    [ -f "$meta/requires" ] && sudo cp "$meta/requires" "$d/requires"

    # tar -v prints './usr/bin/x' for files and 'a -> b' for the odd link; the
    # leading './' becomes '/' and directories are dropped, so the list is the
    # same shape lpkg records for a package it installs itself.
    # /tmp is excluded: every package carries the log of its own build, and
    # the assembly empties /tmp afterwards. Recording those made 'lpkg verify'
    # report 88 missing files on a perfectly good image. lpkg's own installer
    # skips /tmp for the same reason.
    sed 's|^\./|/|; s| -> .*||' "$extracted" \
        | grep -v '/$' | grep -v '^/tmp/' | sort -u | sudo tee "$d/files" > /dev/null

    # /etc entries are configuration: their hash now is what lpkg compares
    # against later to tell an edited file from an untouched one.
    ( while IFS= read -r f; do
        case "$f" in /etc/*) ;; *) continue ;; esac
        [ -f "$ROOTFS_DIR$f" ] || continue
        printf '%s\t%s\n' "$f" "$(sha256sum "$ROOTFS_DIR$f" | cut -d" " -f1)"
      done < "$d/files" ) 2>/dev/null | sudo tee "$d/config" > /dev/null
}

sudo rm -rf "$ROOTFS_DIR"
mkdir -v "$ROOTFS_DIR"

MERGE_WORK=$(mktemp -d)
trap 'sudo rm -rf "$MERGE_WORK"' EXIT

# ---------------------------------------------------------------- file policy
# scripts/packages/file-policy.conf says what to do when several packages ship
# the same file. See the comment at the top of that file.
POLICY_FILE="$BASE_DIR/scripts/packages/file-policy.conf"

# strategy_for <absolute path> -> prints the strategy, or nothing
strategy_for() {
    local path="$1" pat strat
    while read -r pat strat _; do
        case "$pat" in ''|'#'*) continue ;; esac
        # shellcheck disable=SC2254
        case "$path" in $pat) echo "$strat"; return 0 ;; esac
    done < "$POLICY_FILE"
    return 1
}

# the literal paths to merge, as "path field" - globs cannot be snapshotted
MERGE_PATHS=$(awk '$1 !~ /^#/ && $2 ~ /^merge-lines:/ && $1 !~ /[*?]/ {
                       split($2, a, ":"); print substr($1, 2) " " a[2] }' "$POLICY_FILE")
DROP_GLOBS=$(awk '$1 !~ /^#/ && ($2 == "drop" || $2 == "regenerate") { print $1 }' "$POLICY_FILE")

# Keep every entry the previous state had which the copy just unpacked does not
# mention. Keyed on <field>, so passwd, group, shadow and gshadow stay in step.
apply_merges() {
    local path field prev recovered
    while read -r path field; do
        [ -n "$path" ] || continue
        prev="$MERGE_WORK/$(echo "$path" | tr / _)"
        [ -f "$prev" ] || continue
        [ -f "$ROOTFS_DIR/$path" ] || { sudo cp -a "$prev" "$ROOTFS_DIR/$path"; continue; }
        recovered=$(sudo awk -F: -v f="$field" '
            NR == FNR { if ($f != "") have[$f] = 1; next }
            $f != "" && !($f in have) { print $f }
        ' "$ROOTFS_DIR/$path" "$prev" | tr '\n' ' ')
        [ -n "$recovered" ] || continue
        # NOTE written through a temporary file. Piping awk straight into
        # 'tee $ROOTFS_DIR/$path' truncates that file while awk is reading it,
        # and the merge then silently keeps only part of what it recovered.
        sudo awk -F: -v f="$field" '
            NR == FNR { if ($f != "") have[$f] = 1; print; next }
            $f != "" && !($f in have) { print }
        ' "$ROOTFS_DIR/$path" "$prev" > "$MERGE_WORK/merged"
        sudo cp "$MERGE_WORK/merged" "$ROOTFS_DIR/$path"
        sudo rm -f "$MERGE_WORK/merged"
        echo "  kept in $path: $recovered"
    done <<< "$MERGE_PATHS"
    return 0
}

snapshot_merge_paths() {
    local path field
    while read -r path field; do
        [ -n "$path" ] || continue
        if [ -f "$ROOTFS_DIR/$path" ]; then
            sudo cp -a "$ROOTFS_DIR/$path" "$MERGE_WORK/$(echo "$path" | tr / _)"
        fi
    done <<< "$MERGE_PATHS"
    # NOTE the explicit return. Ending on a test which is false - and on the
    # first package none of these files exist yet - makes the loop, and so the
    # function, return non zero, and 'set -e' then kills the build with no
    # message at all.
    return 0
}

# 'drop' and 'regenerate' both mean the file must not be installed from a
# package. The regenerated ones are rebuilt afterwards by regen().
apply_drops() {
    local glob n=0
    while read -r glob; do
        [ -n "$glob" ] || continue
        for f in $(sudo sh -c "ls -d $ROOTFS_DIR$glob 2>/dev/null" || true); do
            sudo rm -rf "$f"; n=$((n + 1))
        done
    done <<< "$DROP_GLOBS"
    [ "$n" -gt 0 ] && echo "  removed $n file(s) which no image should carry"
    return 0
}

# The core and the distro packages are installed together, in the order they
# were built, rather than the core first and the distro second.
#
# Several packages write the same file - /etc/passwd is the one that matters,
# every package adding a service user carries the whole file as it looked when
# that package was built. The package built last holds the most complete copy,
# so it has to be the one unpacked last, whichever list happens to name it.
wanted=$( { read_pkglist "$CORE_DIR/packages.list"
            read_pkglist "$DISTRO_DIR/packages.list"; } | sort -u )

# Everything named has to be in the cache before anything is unpacked. The
# install loop checks each package as it reaches it, which is correct but tells
# you about them one per run: three missing packages take three builds to find,
# and each of those builds has already half assembled a tree before it stops.
#
# The distinction that matters is which list the missing ones came from. A
# package the book builds is missing because 'make packages' has not been run.
# A recipe the distro brought of its own is missing because
# 'make distro-packages' has not been run - a step that does not exist for the
# distros in this repository, so it is exactly the one a client forgets. Same
# symptom, different fix, and saying which is the whole value of checking here.
missing=$(printf '%s\n' "$wanted" | while read -r package; do
    [ -n "$package" ] || continue
    [ -f "packages/$package" ] || echo "$package"
done)
if [ -n "$missing" ]; then
    own=""
    if [ -d "$DISTRO_DIR/packages" ]; then
        own=$(printf '%s\n' "$missing" | grep -xF -f \
            <( cd "$DISTRO_DIR/packages" && ls *.sh 2>/dev/null | sed 's|\.sh$|.tar.gz|' ) || true)
    fi
    theirs=$(printf '%s\n' "$missing" | { [ -n "$own" ] && grep -vxF "$own" || cat; })

    echo "'$distro' names packages which are not in the cache:"
    if [ -n "$theirs" ]; then
        echo "
  built by this repository:"
        printf '%s\n' "$theirs" | sed 's/^/      /'
        echo "
    sudo make packages"
    fi
    if [ -n "$own" ]; then
        echo "
  brought by the distro itself:"
        printf '%s\n' "$own" | sed 's/^/      /'
        echo "
    sudo make distro-packages DISTRO=$distro"
    fi
    echo
    exit 1
fi

# a package which build-packages.sh does not build has no place in the order,
# it is installed first so that a built package can still override it
unknown=$(printf '%s\n' "$wanted" | grep -vxF -f <(build_order) || true)
if [ -n "$unknown" ]; then
    echo "Installing the packages which are not built by build-packages.sh..."
    printf '%s\n' "$unknown" | sed 's/^/  /'
    printf '%s\n' "$unknown" | install_packages
fi

# Every file under /etc or /var which more than one package ships needs a line
# in the policy. Without one the last package unpacked wins and whatever the
# others put there is gone - which is how /etc/passwd lost the dhcpcd and sshd
# accounts while both packages were installed, and why that only showed up when
# the distro was booted.
#
# Refusing here is the whole point of the policy file: a file which starts
# being shared cannot slip in unnoticed, it stops the assembly and has to be
# decided about.
FILE_INDEX="${LFS_PACKAGES:-packages}/.files"
if [ ! -f "$FILE_INDEX" ] || [ -n "$(find "${LFS_PACKAGES:-packages}" -name '*.tar.gz' -newer "$FILE_INDEX" -print -quit 2>/dev/null)" ]; then
    echo "Indexing the files which several packages ship..."
    "$BASE_DIR/scripts/packages/build-file-index.sh"
fi

echo "Checking the shared files against the policy..."
undecided=0
while read -r path pkgs; do
    [ -n "$path" ] || continue
    if ! strategy_for "$path" > /dev/null; then
        echo "  $path
      shipped by:$pkgs
      no policy: the last of them unpacked would win and the rest be lost"
        undecided=$((undecided + 1))
    fi
done < "$FILE_INDEX"
if [ "$undecided" -gt 0 ]; then
    echo "
$undecided shared file(s) have no entry in scripts/packages/file-policy.conf.
Add one for each, choosing merge-lines:<field>, regenerate, drop or last-wins.
last-wins is the behaviour without a policy - stating it records that someone
looked at the file and decided, which is the difference this check exists for."
    exit 1
fi
echo "  every shared file has a policy"

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

# Every package carries what its build left in /tmp: always its own build log,
# and for the few whose clean up did not run, the whole unpacked source tree.
# None of it belongs in an image - /tmp is scratch space the boot scripts clear
# on the way up - so it is emptied here once, rather than chased through the
# build scripts one at a time.
# The one deletion the account merge cannot express. 8.85-clean runs
# 'userdel -r tester' to remove the account the test suites run as, but it says
# so only by writing an /etc/passwd without it, which is indistinguishable from
# one written before the account existed. The merge therefore keeps tester, and
# it is removed here instead. Nothing should ship a login which exists to run
# a compiler test suite.
if [ -f "$ROOTFS_DIR/etc/passwd" ] && sudo grep -q "^tester:" "$ROOTFS_DIR/etc/passwd"; then
    echo "Removing the tester account..."
    for f in etc/passwd etc/group etc/shadow etc/gshadow; do
        [ -f "$ROOTFS_DIR/$f" ] || continue
        sudo sed -i '/^tester:/d' "$ROOTFS_DIR/$f"
    done
    sudo rm -rf "$ROOTFS_DIR/home/tester"
fi

# 'drop' and 'regenerate' in the policy: files which must not be installed
# from a package, removed here before the regenerated ones are rebuilt.
echo "Applying the file policy..."
apply_drops

echo "Emptying /tmp..."
sudo rm -rf "${ROOTFS_DIR:?}/tmp"
sudo install -d -m1777 "$ROOTFS_DIR/tmp"

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

# The fingerprint of the core this rootfs was assembled from.
#
# BUILD_ID says which run produced the tree and changes every time; ABI_ID
# says which world its binaries belong to and changes only when the core does.
# It is what a package repository is keyed on, so a system can tell whether a
# published package was compiled against the same glibc and openssl it has.
#
# Not fatal when it cannot be computed - a rootfs assembled without the
# metadata index is still a rootfs, and saying nothing is better than stamping
# an id which describes nothing.
ABI_ID=$("$BASE_DIR/scripts/packages/abi-id.sh" 2>/dev/null || true)
if [ -z "$ABI_ID" ]; then
    echo "  no ABI id (run 'make packages-meta'); os-release will not carry one"
fi

sudo tee "$ROOTFS_DIR/etc/os-release" > /dev/null <<EOF
NAME="$NAME"
ID=$ID
VERSION="$VERSION"
VERSION_ID=$VERSION
PRETTY_NAME="$PRETTY_NAME"
BUILD_ID=$BUILD_ID${ABI_ID:+
ABI_ID=$ABI_ID}
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
    # Actively write a field with no usable password, rather than leaving
    # whatever the packages happened to carry.
    #
    # This branch used to write nothing, and that was wrong in the dangerous
    # direction. /etc/shadow is a shared file, so a package captures the whole
    # of it, not its own line - and any package built after a root password
    # existed in the base layer carries that hash. Measured: 4-make-shadow bakes
    # one at build time, and 14-make-dhcpcd, 4-make-openssh and 8.85-clean all
    # carry a copy of it. The account merge then faithfully preserves it. So a
    # distro that configured no password still shipped one, while this script
    # printed that the account was locked.
    #
    # '*' rather than '!': measured on hardware, sshd built without linux-pam
    # treats a '!'-prefixed field as a locked *account* and refuses public key
    # logins too, which would make a key-authorised appliance unreachable. '*'
    # denies every password and leaves key authentication working.
    echo "No root password configured; writing an account with none."
    sudo sed -i "s|^root:[^:]*:|root:*:|" "$ROOTFS_DIR/etc/shadow"
    echo "  No password authenticates root, here or over ssh. Public key logins
  are unaffected - a distro shipping root/.ssh/authorized_keys is the expected
  case. For a console, run agetty with --autologin, or set ROOT_PASSWORD in
  distro.conf. 'init=/bin/bash' on the kernel command line remains the last
  resort."
fi

# NOTE --no-preserve=ownership is what keeps these files owned by root. Plain
# 'cp -a' carries the ownership of the working copy across, and because files/.
# maps onto /, that reaches the directories too: /, /etc and /usr all end up
# owned by whichever uid happens to own the checkout. Nothing breaks, so it is
# not noticed, but any account later created with that uid owns /etc.
# The core files come first: they hold what every distro needs regardless of
# which packages it picks, such as the module blacklists for hardware quirks.
# The distro files are applied after, so a distro can override any of them.
if [ -d "$CORE_DIR/files" ]; then
    echo "Applying the core files..."
    sudo cp -a --no-preserve=ownership "$CORE_DIR/files/." "$ROOTFS_DIR/"
fi

# the files of the distro override the packages and the generated files
if [ -d "$DISTRO_DIR/files" ]; then
    echo "Applying the $distro files..."
    sudo cp -a --no-preserve=ownership "$DISTRO_DIR/files/." "$ROOTFS_DIR/"
fi

# Files which are generated from the contents of the tree, not authored. Each
# is written by whichever package happened to install last among those that
# touch it, and then goes stale as later packages add to what it indexes -
# ld.so.cache, for instance, arrives knowing nothing of gtk, mesa or firefox,
# because the last package to ship one was built long before them.
#
# Nothing fails outright: the loader falls back to searching /usr/lib when the
# cache misses. They are regenerated here so the tree describes itself rather
# than describing whatever existed when a package was built.
#
# Each is guarded on its tool being installed: a distro without gtk has no
# gtk-update-icon-cache and needs no icon cache.
#
# NOTE this has to run after the top level symlinks exist. Before them there
# is no /lib64/ld-linux-x86-64.so.2, so nothing dynamically linked can run in
# the chroot and every tool here fails - except ldconfig, which is static and
# succeeds, which makes the mistake look like a problem with the others.
echo "Regenerating the caches which describe the tree..."
regen() {
    # regen <description> <command...>
    local what="$1"; shift
    # the tool is tested from here, not with 'chroot test': test is itself a
    # binary which need not be installed, and chrooting to it fails silently
    [ -x "$ROOTFS_DIR$1" ] || return 0
    if sudo chroot "$ROOTFS_DIR" "$@" > /dev/null 2>&1; then
        echo "  $what"
    else
        echo "  $what FAILED"
    fi
}
regen "shared library cache"    /usr/sbin/ldconfig
regen "mime database"           /usr/bin/update-mime-database /usr/share/mime
regen "glib schemas"            /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas
regen "gdk-pixbuf loaders"      /usr/bin/gdk-pixbuf-query-loaders --update-cache
regen "font cache"              /usr/bin/fc-cache -s
regen "icon cache"              /usr/bin/gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor

# ------------------------------------------------------------------ lpkg
#
# The assembled tree gets the package manager, the table it decides shared
# files with, and the key it verifies a channel against.
#
# The database was written package by package as they were unpacked; 'owners'
# is the index over all of it, and is what makes removing a package safe -
# a path several packages ship must survive the removal of one of them.
echo "Installing lpkg and the package database..."

# lpkg itself, its soname scanner and its file-policy table arrive as the
# x-make-lpkg package, which distros/core/packages.list installs like any
# other - so it is owned, upgradable and able to replace itself. Only the two
# files which are properties of this installation rather than of the package
# are written here.
if [ ! -x "$ROOTFS_DIR/usr/bin/lpkg" ]; then
    echo "  WARNING: no /usr/bin/lpkg in the assembled tree."
    echo "  x-make-lpkg.tar.gz is missing from the package list; the system will"
    echo "  have a package database and nothing able to read it."
fi

# The trusted key is the one thing which cannot come from the repository: a
# channel that supplies the key it is checked against is checking nothing. It
# is baked in here, from whatever key this build publishes with, and a system
# with no key installed says so on every sync rather than trusting silently.
# The signing key is the publisher's, and this is usually run through sudo -
# the tree is root owned - so $HOME is /root and the key is not there. Looking
# in the invoking user's home as well is the difference between an image which
# verifies its channel and one which silently does not.
SIGNING_KEY=""
for candidate in \
    "${REPO_PUBKEY:-}" \
    "$HOME/.config/lfs/repo-signing.key" \
    "$(getent passwd "${SUDO_USER:-}" 2>/dev/null | cut -d: -f6)/.config/lfs/repo-signing.key"
do
    case "$candidate" in ""|"/.config/lfs/repo-signing.key") continue ;; esac
    [ -f "$candidate" ] && { SIGNING_KEY="$candidate"; break; }
done

if [ -n "${REPO_PUBKEY:-}" ] && [ -f "$REPO_PUBKEY" ]; then
    sudo install -Dm644 "$REPO_PUBKEY" "$ROOTFS_DIR/etc/lpkg/trusted.pub"
    echo "  trusted key from $REPO_PUBKEY"
elif [ -n "$SIGNING_KEY" ]; then
    openssl pkey -in "$SIGNING_KEY" -pubout 2>/dev/null \
        | sudo tee "$ROOTFS_DIR/etc/lpkg/trusted.pub" > /dev/null
    echo "  trusted key derived from $SIGNING_KEY"
else
    echo "  no signing key found - this image will not verify a channel."
    echo "  Publish with 'make repo' first, or set REPO_PUBKEY."
fi

if [ -n "${REPO_URL:-}" ]; then
    printf 'REPO_URL=%s\n' "$REPO_URL" | sudo tee "$ROOTFS_DIR/etc/lpkg/lpkg.conf" > /dev/null
    echo "  channel $REPO_URL"
else
    # Written empty rather than left out, so the file is there to edit and
    # 'lpkg sync' says what is missing instead of what is malformed.
    printf '# REPO_URL=https://example.org/repo\n' | sudo tee "$ROOTFS_DIR/etc/lpkg/lpkg.conf" > /dev/null
    echo "  no REPO_URL set; /etc/lpkg/lpkg.conf is a stub to fill in"
fi

# The database is written package by package as they are unpacked, which is
# the only moment the list of what each one brought is available. By the end
# of assembly that list is no longer true of the tree:
#
#   file-policy 'drop' and 'regenerate' remove paths after they were recorded
#   - /etc/passwd-, /var/log/lastlog, /etc/.pwd.lock and the rest
#   merges rewrite /etc/passwd and friends, so the hash taken at extraction
#   is not the hash of the file that ended up there
#   the distro's own files/ and the identity files overwrite more of /etc
#   caches are regenerated from the finished tree
#
# So it is reconciled here, against what is actually on disk. Without this a
# freshly assembled image reported 19 files missing and 21 edited before
# anybody had touched it, which is exactly the noise that makes 'lpkg verify'
# worth ignoring.
echo "  reconciling the database with the finished tree..."
# Run as root in one shell: parts of the tree are not readable otherwise, and
# a path wrongly judged absent would be dropped from the package that owns it.
sudo bash -s "$LPKG_DB" "$ROOTFS_DIR" <<'RECONCILE'
db="$1"; root="$2"
for d in "$db"/db/*/; do
    [ -d "$d" ] || continue
    [ -f "$d/files" ] || continue
    kept="$d/.files.kept"
    : > "$kept"
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        if [ -e "$root$f" ] || [ -L "$root$f" ]; then printf '%s\n' "$f" >> "$kept"; fi
    done < "$d/files"
    mv "$kept" "$d/files"

    : > "$d/config"
    while IFS= read -r f; do
        case "$f" in /etc/*) ;; *) continue ;; esac
        [ -f "$root$f" ] || continue
        printf '%s\t%s\n' "$f" "$(sha256sum "$root$f" | cut -d' ' -f1)" >> "$d/config"
    done < "$d/files"
done
RECONCILE

if [ -d "$LPKG_DB/db" ]; then
    ( for d in "$LPKG_DB"/db/*/; do
        [ -d "$d" ] || continue
        n=$(basename "$d")
        [ -f "$d/files" ] || continue
        while IFS= read -r f; do
            [ -n "$f" ] && printf '%s\t%s\n' "$f" "$n"
        done < "$d/files"
      done ) | sort | sudo tee "$LPKG_DB/owners" > /dev/null
    echo "  $(ls "$LPKG_DB/db" | wc -l) packages recorded, $(wc -l < "$LPKG_DB/owners") owned paths"
fi



# how this rootfs was assembled
# build-image.sh needs the distro's own settings - the kernel command line,
# the menu timeout, the extra boot entries - and it runs against rootfs/ with
# no idea where the distro directory was. It used to rebuild the path as
# distros/$DISTRO, which stops being possible the moment a distro can live
# anywhere. So the files travel with the rootfs that was built from them.
sudo rm -rf "$ROOTFS_DIR/etc/lfs-distro.d"
sudo install -d -m755 "$ROOTFS_DIR/etc/lfs-distro.d"
for f in distro.conf boot-entries check.ignore; do
    if [ -f "$DISTRO_DIR/$f" ]; then
        sudo cp "$DISTRO_DIR/$f" "$ROOTFS_DIR/etc/lfs-distro.d/$f"
    fi
done

sudo tee "$ROOTFS_DIR/etc/lfs-distro" > /dev/null <<EOF
DISTRO=$distro
ID=$ID
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

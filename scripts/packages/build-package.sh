#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
__NAME__=$(basename "$0")

for var in LFS LFS_BASE LFS_PACKAGE LFS_PACKAGES; do
    if [ "${!var}" == "" ]; then
        echo "$__NAME__: $var is not defined"
        exit 1
    fi
done

# The build is finished by the time $LFS is unmounted, and the package is made
# from the upper layer afterwards. A busy mount point therefore has to be
# retried rather than allowed to fail: it is enough for a shell to sit with its
# working directory inside the overlay - watching the build log lives there -
# and a completed build is thrown away for no reason. The last resort is a lazy
# unmount, which detaches the tree now and releases it when the last user goes.
unmount_lfs() {
    local i out
    for i in 1 2 3 4 5; do
        if out=$(umount "$LFS" 2>&1); then
            return 0
        fi
        echo "$__NAME__: $LFS is busy, retrying ($i/5).."
        sleep 2
    done
    echo "$__NAME__: could not unmount $LFS: $out"
    echo "$__NAME__: held by:"
    fuser -vm "$LFS" 2>&1 | sed 's/^/    /' || true
    echo "$__NAME__: detaching it lazily so the finished build is not lost"
    umount -l "$LFS"
}

error_trap() {
    set +e
    # $2 is the command bash was running when the trap fired. A line number on
    # its own says where to look but not what went wrong, and the real error is
    # usually already scrolled past by the time this prints.
    echo -e "\n$__NAME__: failed at line $1${2:+: $2}"
    sync
    $SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1
    umount $LFS
    exit 1
}

trap 'error_trap $LINENO "$BASH_COMMAND"' ERR

o_force=0
script_path=""
while [[ $# -gt 0 ]]; do
    case $1 in
    -f|--force)
        o_force=1
        shift
        ;;
    -*|--*)
        echo ": Unknown option $1"
        exit 1
        ;;
    *)
        if [[ "$script_path" != "" ]]; then
            echo "$__NAME__: only one positional argument expected - script_path"
            exit 1
        fi
        script_path="$1"
        shift
        ;;
    esac
done
if [ "$script_path" == "" ]; then
    echo "Missing argument: script_path"
    exit 1
fi

script_name=$(basename -- "$script_path")
# flag file on the host
flag_file="tmp/${script_name%.*}.ready"
# log file on the chroot system
log_file="${script_name%.*}.log"
echo -ne "...... $script_path -> $log_file"
if [[ ! -f "$flag_file" || $o_force -eq 1 ]]; then
    # An overlay already on $LFS means a previous build did not unmount it -
    # it was interrupted, or its unmount failed. Mounting again stacks a second
    # overlay on top of the first, and nothing says so: the mounts pile up, a
    # build then reads through one layer and writes into another, and the
    # package made from $LFS_PACKAGE is whatever that mixture produced. Six of
    # them had accumulated before this check existed.
    #
    # Refusing is the only safe answer. Clearing it automatically would throw
    # away the upper layer of a build which may still be running.
    if mount | grep -q " on $(readlink -f "$LFS") type overlay"; then
        echo -ne "\r\n$__NAME__: $LFS already has an overlay mounted."
        echo "
Another build is either running or was interrupted without unmounting. Check
with 'mount | grep $LFS'. If nothing is running, unmount every stacked layer:

    for m in run sys proc dev/pts dev; do sudo umount $LFS/\$m; done
    while mount | grep -q \" on \$(readlink -f $LFS) type overlay\"; do sudo umount $LFS; done
"
        exit 1
    fi

    # mount overlay to isolate the installed files in $LFS_PACKAGE
    sync
    # Clean package directory
    rm -rf "$LFS_PACKAGE"/*
    mount -t overlay overlay \
        "-olowerdir=$LFS_BASE,upperdir=$LFS_PACKAGE,workdir=overlay/work" \
        "$LFS"

    script_path_local=$(echo $LFS/$script_path | sed "s/\/\//\//g")
    if [ ! -f "$script_path_local" ]; then
        echo -ne "\r\n$__NAME__: Can't find script $script_path_local"
        exit 1
    fi

    # mount vkfs to the chroot directory
    $SCRIPT_DIR/7.3-mount-vkfs.sh > /dev/null
    # The build failing inside the chroot is reported below, with the tail of
    # its log. Without disarming the trap the chroot returning non zero fires
    # it first, which unmounts and leaves only a line number behind.
    trap - ERR
    /usr/sbin/chroot "$LFS" /usr/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PS1='(lfs chroot) \u:\w\$ ' \
        PATH=/usr/bin:/usr/sbin \
        $(cat .env | xargs) \
        /bin/bash --login +h -c "sh -c '$script_path > /tmp/$log_file 2>&1'"
    status=$?
    trap 'error_trap $LINENO "$BASH_COMMAND"' ERR
    sync
    $SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1
    sync
    unmount_lfs
else
    echo -ne "\rskip   $script_path"; echo
    exit 0
fi
if [ $status -eq 0 ]; then
    echo -ne "\rpassed"; echo
    # Record which files this package created and which it changed.
    #
    # A package is the upper layer of an overlay: the final content of every
    # file its build wrote. That cannot tell you whether it created /etc/passwd
    # or added one line to someone else's - both look the same afterwards. The
    # answer is here though, because the layer underneath is still $LFS_BASE,
    # so the two are compared while both exist and the result is stored in the
    # package. build-distro.sh uses it to tell a package replacing a file it
    # owns from several packages each adding to a shared one.
    meta="$LFS_PACKAGE/.meta"
    rm -rf "$meta"; mkdir -p "$meta"

    # A file already in the base is not necessarily someone else's: on a
    # rebuild this package's own files are there from its previous build. The
    # previous package says which those are, so a rebuild is not mistaken for
    # one package changing another's file.
    mine="$meta/.mine"
    : > "$mine"
    if [ -f "$LFS_PACKAGES/${script_name%.*}.tar.gz" ]; then
        tar tzf "$LFS_PACKAGES/${script_name%.*}.tar.gz" 2>/dev/null \
            | sed 's|^\./||' | grep -v '/$' > "$mine" || true
    fi

    # Symlinks and whiteouts are walked as well as regular files.
    #
    # It used to be '-type f' alone, which is right for assembly - the tarball
    # carries every entry regardless of what this records - and wrong the
    # moment anything reads these lists to find out who owns what.
    # /usr/lib/libz.so is a symlink, so it appeared in no list at all, and
    # removing zlib on that basis would leave it behind pointing at nothing.
    #
    # A char device in an overlay upper layer is not a device, it is a
    # whiteout: the package deleting a file the layer below it has. That is
    # neither created nor modified, so it gets a list of its own.
    ( cd "$LFS_PACKAGE" && find . \( -type f -o -type l -o -type c \) \
          -not -path './.meta/*' -print ) \
        | sed 's|^\./||' \
        | while read -r rel; do
            case "$rel" in tmp/*) continue ;; esac
            if [ -c "$LFS_PACKAGE/$rel" ]; then
                echo "$rel" >> "$meta/removed"
            # -e follows the link, so a symlink to something which does not
            # exist needs -L as well or it reads as absent from the base
            elif { [ -e "$LFS_BASE/$rel" ] || [ -L "$LFS_BASE/$rel" ]; } \
                 && ! grep -qxF "$rel" "$mine"; then
                echo "$rel" >> "$meta/modified"
            else
                echo "$rel" >> "$meta/created"
            fi
        done
    touch "$meta/created" "$meta/modified" "$meta/removed"
    rm -f "$mine"

    # A build which touched nothing is a failed build which happened to exit 0.
    #
    # The recipes are long '&&' chains, and an edit which breaks the chain
    # early leaves the exit status of the last command that did run - so the
    # build reports 'passed', an empty layer is archived over the previous
    # package, and the distro silently keeps whatever it had. Refusing here is
    # the cheapest place to catch it: everything needed to tell is already
    # counted.
    if [ ! -s "$meta/created" ] && [ ! -s "$meta/modified" ] && [ ! -s "$meta/removed" ]; then
        echo -ne "\rfailed"; echo
        echo "$__NAME__: $script_path exited 0 but wrote no files."
        echo "The package would be empty, so it is not archived - the previous one is kept."
        echo "Check the '&&' chain in the recipe, and the tail of $log_file:"
        tail -n 25 "$LFS_PACKAGE/tmp/$log_file" 2>/dev/null | sed 's/^/    /'
        exit 1
    fi

    # What this package links against, read out of the binaries it just built.
    #
    # The overlay upper layer is sitting unpacked in $LFS_PACKAGE, so this
    # costs a walk of one package's bin and lib directories. Deriving the same
    # thing afterwards means unpacking every tarball in the cache instead -
    # 3.3 GB of them - which is what build-deps.sh used to do on every run.
    if [ -r "$SCRIPT_DIR/pkg-elf.sh" ]; then
        # shellcheck source=scripts/packages/pkg-elf.sh
        . "$SCRIPT_DIR/pkg-elf.sh"
        pkg_scan_elf "$LFS_PACKAGE" "$meta/provides" "$meta/requires"
    fi

    # What this package is, as opposed to which script built it.
    #
    # The file name stays the recipe coordinate - packages.list, the dependency
    # graph and build-distro.sh all address packages that way, and renaming the
    # build cache would buy nothing. This is the identity the cache does not
    # carry: what a repository would publish it as.
    if [ -r "$SCRIPT_DIR/pkg-header.sh" ]; then
        # shellcheck source=scripts/packages/pkg-header.sh
        . "$SCRIPT_DIR/pkg-header.sh"
        # build-packages.sh passes '/scripts/packages/...' and the 'make
        # build-package' target passes 'scripts/packages/...' - so the leading
        # separator is normalised rather than assumed. Without this the two
        # were concatenated into 'overlay/basescripts/...', the recipe could
        # not be read, and the package was archived with no identity while
        # reporting that it had declared none.
        recipe_file="$LFS_BASE/${script_path#/}"
        if [ ! -r "$recipe_file" ]; then
            echo
            echo "$__NAME__: cannot read $recipe_file to record what this package is."
            echo "Run 'make update-scripts' so the build base has the current recipes."
        elif pkg_read_headers "$recipe_file" && pkg_validate "$LFS_BASE/sources"; then
            {
                echo "name=$PKG_NAME"
                echo "version=$PKG_VERSION"
                echo "release=$PKG_RELEASE"
                echo "arch=${PKG_ARCH:-x86_64}"
                echo "class=$PKG_CLASS"
                echo "recipe=$PKG_RECIPE"
                # so a forgotten '# RELEASE:' bump is detectable at publish
                echo "recipesum=$(pkg_recipe_sum "$recipe_file")"
                echo "source=${PKG_TARBALL:-}"
                echo "builddate=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            } > "$meta/PKGINFO"
        else
            # Not fatal. The package is good; only its identity is missing, and
            # 'make packages-lint' is where that is meant to be caught.
            echo
            echo "$__NAME__: $script_name declares no usable identity, .meta/PKGINFO omitted:"
            printf '    %s\n' "${PKG_FAULTS[@]}"
        fi
    fi

    # Archive package
    package_name="$LFS_PACKAGES/${script_name%.*}.tar.gz"
    tar cfz "$package_name" -C "$LFS_PACKAGE" .
    # Copy all but delete special files/dirs from destination
    "$SCRIPT_DIR/copy-or-del.sh" "$LFS_PACKAGE" "$LFS_BASE"
    # Clean package directory
    rm -rf "$LFS_PACKAGE"/*
    # Mark this build has been passed as the same package successful install is not guaranteed
    touch "$flag_file"
else
    echo -ne "\rfailed"; echo
    # The log_file should remain in $LFS_PACKAGE/tmp
    # $LFS is unmounted by now, the log survives in the package layer
    tail -n 25 "$LFS_PACKAGE/tmp/$log_file"
    echo
    # Exit with failure
    exit 1
fi

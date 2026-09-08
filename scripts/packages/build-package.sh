#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
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
    fs_sync "$LFS_PACKAGE"
    $SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1
    umount $LFS
    exit 1
}


# sync the filesystem we are actually writing, not every filesystem mounted.
#
# A bare 'sync' flushes everything the kernel knows about, and under WSL2 that
# includes the Windows-backed 9p mounts - where it can block for many minutes
# regardless of whether anything of ours is dirty. Measured mid-build with
# 14 MB dirty and zero writeback, a global sync sat there for thirteen
# minutes; 'sync -f' on the tree being written returned in five milliseconds.
fs_sync() {
    local target="${1:-.}"
    [ -e "$target" ] || target=.
    sync -f "$target" 2>/dev/null || true
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
    # One build at a time, across every project that builds into this tree.
    #
    # $LFS and $LFS_PACKAGE are one overlay and one upper layer, shared by
    # 'make packages' here and 'make distro-packages' from a distro kept in
    # another repository. Two builds in them at once destroy each other's work,
    # and they do it quietly.
    #
    # Twice, measured. On 6 September a ruby build and an audi build overlapped
    # and ruby's package came out holding 5166 audi files and no ruby at all -
    # a plausible looking 223 MB tarball whose only symptom appeared two days
    # later as 'Ruby 2.5 or higher is required' in the middle of WebKit's
    # configure. On 8 September the rebuild of that same package was wiped
    # mid-copy by an inteliboy-adapters build clearing $LFS_PACKAGE, and
    # copy-or-del.sh reported a ruby documentation file it had just listed as
    # 'No such file or directory'.
    #
    # The overlay check below is not enough on its own. It only sees a build
    # that still has $LFS mounted, and the damage happens after the unmount:
    # stripping, tarring, copying into the base and clearing the upper layer
    # all run with nothing mounted and nothing held.
    #
    # Taken here rather than at the top of the script, so that the ~250 recipes
    # a run skips do not queue behind a build they will not perform. Held to
    # the end of the script, which is where the upper layer is cleared, and
    # released by the shell closing the descriptor however this exits.
    BUILD_LOCK="$BASE_DIR/.lfs-build.lock"
    [ -e "$BUILD_LOCK" ] || : > "$BUILD_LOCK" 2>/dev/null || true
    # Read-only: flock(2) locks the descriptor whatever it was opened for, and
    # these scripts do not all run as the same user - build-package.sh under
    # sudo, build-repo.sh as the invoking user. Opening for write is what makes
    # the file's ownership decide who may ever take the lock again.
    if exec 7<"$BUILD_LOCK" 2>/dev/null; then
        if ! flock -n 7; then
            echo -ne "\r\n$__NAME__: another build holds $BUILD_LOCK; waiting for it\n"
            flock 7
        fi
    else
        echo "$__NAME__: cannot open $BUILD_LOCK; building without a lock"
    fi

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
    fs_sync "$LFS_PACKAGE"
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
    fs_sync "$LFS_PACKAGE"
    $SCRIPT_DIR/11-unmount-vkfs.sh > /dev/null 2>&1
    fs_sync "$LFS_PACKAGE"
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
    # ---- debug symbols ---------------------------------------------------
    #
    # Stripped here, so a package is born the size it will be installed at.
    #
    # It used to happen only in build-distro.sh, at image assembly, which left
    # two problems. The channel carried the symbols - gcc published at 724 MB
    # against 347 MB stripped, and every install downloaded the difference.
    # And a system built from an image had stripped binaries while the same
    # package installed by lpkg did not, so the two diverged by how they were
    # put together rather than by what was installed.
    #
    # Same rules build-distro.sh uses: a static library or a kernel module
    # keeps the symbols it is linked or resolved against, everything else
    # loses what is unneeded, and anything which is not ELF is left alone.
    if [ "${STRIP_PACKAGES:-1}" = 1 ]; then
        before=$(du -sk "$LFS_PACKAGE" | cut -f1)
        while IFS= read -r -d '' f; do
            [ "$(head -c4 "$f" 2>/dev/null | od -An -tx1 | tr -d ' ')" = "7f454c46" ] || continue
            case "$f" in
            # grub resolves its modules by symbol at load time, so stripping
            # them leaves a boot loader that drops to the rescue shell with
            # "no such partition". build-distro.sh has excluded this path for
            # exactly that reason since before any of this existed; the rule
            # was not carried over when the strip moved here, and the result
            # was an unbootable image.
            */usr/lib/grub/*) continue ;;
                *.a|*.ko) strip --strip-debug    "$f" 2>/dev/null ;;
                *)        strip --strip-unneeded "$f" 2>/dev/null ;;
            esac
        done < <(find "$LFS_PACKAGE" -type f -not -path "$LFS_PACKAGE/tmp/*" -print0 2>/dev/null)
        after=$(du -sk "$LFS_PACKAGE" | cut -f1)
        [ "$before" -gt "$after" ] && \
            echo "       stripped $(( (before - after) / 1024 )) MB of debug symbols"
    fi

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
            # The core this package was compiled against.
            #
            # Sonames do not carry it. A binary needing GLIBC_2.38 asks the
            # loader for libc.so.6 - which is what every glibc since 1997 has
            # called itself - so the dependency resolves cleanly against a
            # libc six years too old, and the program dies on its first exec
            # instead of failing to install. Symbol versions live in
            # .gnu.version_r and nothing here reads that section, so the
            # dependency graph cannot see this class of breakage at all.
            #
            # The channel path is the guard: a system can only fetch from the
            # ABI it is. But a package handed over on a USB stick has left its
            # channel behind, and 'lpkg install --from' had nothing to check
            # beyond the class. This is what it now checks.
            #
            # Not stamped on core packages. They are what the id is computed
            # from, so the value here would name the core they replace rather
            # than the one they belong to. They are also already refused on a
            # running system, which is the case this protects.
            #
            # Soft on failure: a tree whose metadata index is incomplete still
            # builds packages, it just builds them without this. A missing or
            # stale stamp is caught at publish time by build-repo.sh, which
            # knows the real ABI of the channel it is writing.
            pkg_abi=""
            if [ "$PKG_CLASS" != core ] && [ -x "$SCRIPT_DIR/abi-id.sh" ]; then
                pkg_abi=$("$SCRIPT_DIR/abi-id.sh" 2>/dev/null) || pkg_abi=""
            fi
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
                if [ -n "$pkg_abi" ]; then echo "abi=$pkg_abi"; fi
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
    #
    # Written under the package-cache lock, because a tarball being created is
    # a file that grows: anything reading it meanwhile sees a valid gzip
    # stream of the wrong length. build-repo.sh hardlinks from this directory
    # and records a size and a SHA256 for each package, and it did exactly
    # that to a kernel mid-write - publishing Size 17385428 for a file which
    # settled at 18044817, so the channel verified wrong rather than failing.
    #
# The lock lives beside this tree, not in /tmp.
#
# /tmp is sticky and world-writable, and with fs.protected_regular set the
# kernel refuses to open a regular file there for writing unless the caller
# owns it - root included, capabilities notwithstanding. These scripts do not
# all run as the same user: build-package.sh runs under sudo, while
# build-meta.sh and build-repo.sh run as the invoking user and elevate per
# command. So whoever created the lock first became the only user who could
# ever take it again, and every later run died with
#   /tmp/lfs-packages.lock: Permission denied
# with deleting the file by hand as the only way out.
#
# The repository root is owned by the user, is not sticky, and root writes
# there regardless - so both callers can always open the lock. $LFS_PACKAGES
# would not do: it is root-owned, which fixes the sudo case and breaks the
# other two.
#
# Opened for READING, not writing. flock(2) locks a descriptor and does not
# care how it was opened, but open(2) for write does care: root creating the
# file leaves it mode 644, and the next non-root run then cannot open it at
# all. Reading needs only the read bit, which 644 grants everyone, so either
# user can take the lock whichever of them created the file.

    #
    # The lock is separate from build-meta.sh's. That one guards the metadata
    # index against two of its own runs; this one guards the cache itself, and
    # build-repo.sh calls build-meta.sh as a child - sharing one lock between
    # them would deadlock the parent against its own child.
    package_name="$LFS_PACKAGES/${script_name%.*}.tar.gz"
    CACHE_LOCK="$BASE_DIR/.lfs-packages.lock"
    [ -e "$CACHE_LOCK" ] || : > "$CACHE_LOCK" 2>/dev/null || true
    (
        flock 8
        # ./tmp/* and not ./tmp: the directory entry is real content -
        # 7.5-create-directories.sh ships /tmp as drwxrwxrwt, and dropping it
        # would lose the sticky bit. What is inside it is not. Every recipe
        # writes its build log to /tmp/<recipe>.log, so every package was
        # carrying one, glibc and firefox included, and make-ca carried two
        # mktemp directories besides. The log is still written and still left
        # in $LFS_PACKAGE/tmp, which is where the failure path reads it from
        # after $LFS is unmounted - it is just no longer shipped.
        #
        # Written beside the target and renamed onto it, never written in
        # place. build-repo.sh hardlinks the channel's copy to this very
        # inode, so writing straight onto $package_name rewrites whatever the
        # channel already published under its own name - the bytes change
        # while the name, which the index promises is immutable, does not.
        #
        # Measured: rebuilding lpkg left lpkg-10-1.x86_64.lpkg in the channel
        # holding lpkg 11, flock and all. rename(2) replaces the directory
        # entry and leaves the old inode alone, so a published file keeps the
        # bytes it was published with and 'make repo' decides deliberately
        # whether a new name is warranted.
        #
        # It also makes the cache file atomic: nothing ever reads a tarball
        # that is still being written.
        tar cfz "$package_name.new" --exclude='./tmp/*' -C "$LFS_PACKAGE" .
        mv -f "$package_name.new" "$package_name"
    ) 8<"$CACHE_LOCK"
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

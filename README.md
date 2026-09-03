## Description

This repository contains docker based host system and scripting environment to build bootable iso image with [Linux From Scratch 11.2](https://www.linuxfromscratch.org/lfs/downloads/11.2/LFS-BOOK-11.2.pdf).

## Why

General idea is to learn Linux by building your own system based on the LFS.

## Structure

Scripts are organized to follow closely as possible the book structure.

Every package is built in isolation and archived in packages/, so a distro is
assembled by unpacking a selection of them over a stable core.
The core (distros/core/packages.list) is what an LFS system needs to boot to a
login prompt and is always installed.
A distro is described by its own directory under distros/:

    distros/minimal/distro.conf     identity - name, version, hostname, STRIP
    distros/minimal/packages.list   the packages added on top of the core
    distros/minimal/files/          files copied over the assembled rootfs

## Build

A distro is built in four steps, each one consuming what the previous produced:

    sudo make packages              builds every package from source, once
    make distro DISTRO=minimal      assembles distros/minimal into rootfs/
    make image                      turns rootfs/ into a bootable image.img
    make qemu                       boots image.img

Only one distro is worked on at a time, in the rootfs/ directory.
To start another one, archive the current rootfs first with make docker,
or discard it by passing FORCE=1 to make distro.

## Distro

To see what the assembled rootfs is, read its identity files:

    cat rootfs/etc/os-release       name, version and build id of the distro
    cat rootfs/etc/lfs-distro       which distro was assembled and when

The debug symbols are removed when STRIP=1 in distro.conf, which is what makes
the produced image and docker image small - for the minimal distro it is the
difference between 872 MB and 566 MB. Keep them with

    make distro DISTRO=minimal STRIP=0

To resolve every program of the assembled rootfs against its own libraries, run

    make check

It reports the programs which can not run, which is how a distro missing a
package is found without booting it. `make deps-check` finds the same gaps
before anything is assembled, from a graph derived once with `make deps`:

    make packages-meta       what every built package says about itself
    make deps                deriving the graph from the built packages
    make deps-check          what a distro is missing, before assembling it
    make deps-verify         whether build-packages.sh satisfies the declarations
    make deps-order          an order which does, rebuilds included
    make deps-declared       declared build deps not seen in any binary
    make why PACKAGE=17-make-libnl
    make closure PACKAGES=27-make-fluxbox
    make file-index          the files several packages ship

The graph holds shared library dependencies exactly, because it is read out of
the binaries. Anything else - a dlopened module, a program run by another, a
data file - is declared in the build script, as is the order and the occasional
pair of packages which need each other:

    # BUILD_REQUIRES:    needed to compile this package
    # RUNTIME_REQUIRES:  needed to run it, and not visible in the binaries
    # REBUILD_AFTER:     build this package again once these exist
    # BUILD_ONLY:        a build tool; no distro installs it

A recipe also declares what it builds, as opposed to how it is built:

    # PACKAGE:  zlib              upstream's name for it
    # SOURCE:   zlib-*.tar.xz     the tarball, pinned to exactly one file
    # VERSION:  1.3.1             only when SOURCE cannot give it
    # RELEASE:  1                 bumped by hand when the recipe changes
    # CLASS:    core              core | system | extra | bootstrap

The version is whatever the first `*` of SOURCE matched, so `tcl*-src.tar.gz`
gives 8.6.16 and `expect*.tar.gz` gives 5.45.4 without a table of special
cases. VERSION is written out instead when there is no single tarball to read
it from - the `configure-*` steps build no source, `24-make-xorg-libraries`
builds a list of them, and `unzip60.tar.gz` has no separator to split on.

CLASS says where a package may be installed. `core` is glibc, the kernel and
the rest of what a system cannot replace underneath itself: it is built and
published like anything else but only ever installed into an image or a new
root, never into a running one. `bootstrap` is the chapter 7 tools, built to
build the system and installed as themselves nowhere.

Two recipes may share a PACKAGE name as long as their RELEASE differs, which
is how a rebuild says it supersedes: BLFS builds shadow again against
Linux-PAM and grub again with UEFI, so those are release 2 of the package LFS
installed. What they may not share is name, version and release together.

    make packages-lint       what every recipe says it builds

Run it before `make packages`. A source glob matching two tarballs is handed
to tar as two arguments, which makes tar read the second as a member name of
the first - and it fails that way hours into the build. `Python-*.tar.xz`
matches both Python-3.13.7 and Python-3.10.18, and `Linux-PAM-*.tar.xz`
matches the -docs archive first; the lint is what found those.

Each built package carries its identity in `.meta/PKGINFO`, beside the record
of which files it created, modified and removed, and `.meta/provides` and
`.meta/requires` - the shared libraries it offers and asks for, read out of
its own binaries as it is built. The package file itself keeps its
recipe-coordinate name: `packages.list`, the dependency graph and
build-distro.sh all address packages that way.

`make packages-meta` collects all of that into `packages/.meta-index/`, one
directory per package. Anything built since the recipes started declaring
themselves carries its own answer and is copied out; anything older is
unpacked and scanned once, then cached until it changes. Nothing needs
rebuilding for it, and `make deps` is a join over the index rather than a
walk of 3.3 GB of tarballs.

## ABI

Every package is compiled against one exact core - this glibc, this openssl -
and a package is only installable on a system built from a compatible one.
Nothing in a binary says which, so the core is fingerprinted:

    make abi                 the id of the core the packages were built against
    make abi ARGS=-v         and what went into it

It hashes the name, version and release of the core packages which provide a
shared library, together with the architecture - not the file contents,
because two builds of the same sources are the same ABI. Bumping `# RELEASE:`
on glibc or openssl therefore changes the id, which is the point: a rebuilt
glibc is a new world for everything compiled against it.

Only the packages providing a library, because those are the only ones a
binary can be incompatible with. Half the core provides none - sed, tar, grep,
the bootscripts, the `configure-*` steps, lpkg itself - and counting them made
the id move for reasons that cannot break a binary. With lpkg in the core that
stopped being academic: every update to the package manager would have changed
the ABI, made every published channel unreachable, and needed a reimage to fix
a shell script. The trade is that a new tar in the core no longer invalidates
the channel, which it should not - nothing is compiled against tar.

`build-distro.sh` stamps it into `/etc/os-release` as `ABI_ID`, beside the
`BUILD_ID` which says merely which run produced the tree. It is what the
package repository is keyed on, so a system can tell whether a published
package was built against the libraries it actually has.

## Repository

The built packages are published as a signed repository, one channel per ABI:

    make repo                publishes into repo/<abi>/<arch>
    make repo-verify         checks a channel the way a system would

    repo/92298ab10cdb/x86_64/
        INDEX                one stanza per package
        INDEX.sig            detached signature over INDEX
        zlib-1.3.1-1.x86_64.lpkg

One channel serves every distro built from the same core, because what decides
whether a package will run is the glibc it was linked against and not which
package list happened to include it. `distros/*/packages.list` is a default
selection out of the channel rather than a world of its own - installing `git`
on minimal pulls the same binary full already ships.

This is where recipe coordinates become package names. The build cache goes on
calling it `8.6-make-zlib.tar.gz`, because `packages.list` and the dependency
graph address packages that way; the channel calls it
`zlib-1.3.1-1.x86_64.lpkg`, because that is an identity a system can compare
against what it already has. Packages are hardlinked out of the cache, so
publishing costs no disk.

Everything but `bootstrap` is published. `core` is published too - keeping it
out of a system is the job of its class, not of the repository.

The index carries a SHA256 for every package, so one signature over `INDEX`
covers the channel. The key is generated on first use at
`~/.config/lfs/repo-signing.key` and never lives in this tree: `.env` is
committed and already carries a root password. Set `REPO_KEY` or pass `--key`
to keep it elsewhere.

    make repo-verify ARGS="--pub /path/to/trusted.pub"

`INDEX.pub` is written beside the index for convenience and is not a thing to
trust - anyone who can replace the index can replace the key next to it. The
public half has to reach a system another way, baked into the image.

`make repo` refuses to publish a package whose recipe text changed while its
`# RELEASE:` did not, because a system holding the earlier build would never
see the new one. `ARGS=--force-stale` overrides it for a change which cannot
affect the output. A superseded package stays in the channel and is reported;
`ARGS=--prune` removes what the index no longer names.

`make repo-verify` checks the signature, then every package's size and hash,
then whether every soname the channel requires is provided within it. The last
is what says the channel is closed - a repository can be signed and intact and
still unable to satisfy an install.

`scripts/packages/file-policy.conf` decides what happens when several packages
ship the same file - merged, regenerated, dropped, or the last one kept. A file
under /etc or /var which is shared and has no entry stops the assembly.

A distro may accept a gap on purpose: `distros/<distro>/check.ignore` for an
unresolved file, `deps.ignore` for a package deliberately left out. Both take a
reason next to the entry.

To archive the assembled rootfs as a docker image named after the distro, run

    make docker TAG=20260826

The image is named after the ID of the distro, so the above produces
minimal:20260826 which can be run with

    sudo docker run --rm -it minimal:20260826

## Usage

The produced image.img is flashed on USB stick with the command:

    sudo dd if=image.img of=/dev/sdb status=progress

Boot the PC from the USB stick and log in as root with the password set by
LFS_ROOT_PASSWORD in .env.
The root partition is found by its PARTUUID, so the same image boots from a USB
stick on a PC which already has disks and as the first disk under QEMU.

## QEMU

The image boots with UEFI only, therefore QEMU needs the OVMF firmware:

    sudo apt install qemu-system-x86 ovmf

Then make qemu boots image.img, forwarding QEMU_ARGS to QEMU:

    make qemu
    make qemu QEMU_ARGS="-snapshot"

## License

The work is based on [Linux from Scratch](http://www.linuxfromscratch.org/lfs) project and provided with MIT license.
The initiative is influenced by Ilya Builuk https://github.com/reinterpretcat/lfs

## lpkg

The package manager the assembled system carries. It is part of the core:
`distros/core/packages.list` installs `x-make-lpkg.tar.gz` like any other
package, so lpkg is owned, versioned and visible to itself.

Every command it runs - bash, coreutils, grep, sed, gawk, findutils, tar,
gzip, util-linux and openssl - was already in the core for other reasons, so
lpkg itself adds 40 KB of shell. gzip is on that list because `tar -z` shells
out to it rather than decompressing itself, which is easy to miss: a root
holding tar but not gzip installs nothing and says the package is unreadable.

`curl` and `binutils` are in the core as well. curl is what makes an http or
https `REPO_URL` work - without it a channel has to be a path or a `file://`
URL, which is fine for removable media or an NFS mount and not what most
installations want. It costs 4 MB and its whole soname closure was already
present.

binutils is there for `readelf`, which is how `lpkg build` reads the sonames
out of a package compiled locally; without it such a package records that it
provides and needs nothing, and resolves against nothing. It is the expensive
entry: binutils links against libstdc++ and libgcc_s, which live in the gcc
package, so gcc and flex come with it - 398 MB stripped, against a core that
was 681 MB before. Two ways to make that cheaper, neither taken: splitting
libstdc++ and libgcc_s out of gcc into a gcc-libs package, as other
distributions do, would bring it to about 57 MB, but the build has no way to
say "this recipe writes these files and does not ship them"; or lpkg could run
the scan inside the build chroot, where binutils is already part of the build
root, for nothing at all.

Being in `distros/core/packages.list` and having `# CLASS: core` are separate
things. The list says what is always installed; the class says where a package
may be installed. curl, binutils and lpkg are all in the list and none of them
is class core, so they are always present and can still be upgraded on a
running system.

lpkg upgrades itself. It is `# CLASS: system` rather than core, because the
core restriction exists for things which cannot be swapped under the processes
using them, and a shell script can be - provided the replacement is a new
inode rather than a rewrite of the old one. lpkg extracts with
`--unlink-first`, so the shell running the upgrade keeps reading the file it
started from and the next invocation is the new one. Verified by having a
running lpkg replace itself: the version changed and so did the inode.

`build-distro.sh` adds the two files which are properties of an installation
rather than of a package - `/etc/lpkg/lpkg.conf` and `/etc/lpkg/trusted.pub` -
and a package database recording everything the assembly put there, so a fresh
image knows what is installed on it rather than starting out believing it is
empty.

    lpkg sync                    fetch and verify the channel index
    lpkg install <name>...       install packages and whatever they need
    lpkg remove <name>...        remove packages
    lpkg upgrade [<name>...]     move to what the channel now has
    lpkg list [--upgradable]     what is installed
    lpkg owns <path>             which package a file belongs to
    lpkg verify [<name>...]      installed files against what was recorded

`--root <dir>` acts on another tree, which is how a new root is populated and
how any of this is tested without booting.

Dependencies are sonames. `curl` requires `libssl.so.3` and whatever provides
it satisfies that, which is read out of the binaries rather than declared and
survives a package being renamed or split.

The database lives in `/var/lib/lpkg`: a directory per package holding its
identity, its file list, its sonames and the hashes of its `/etc` files, plus
`owners` mapping every path to the package it came from. That index is what
makes removal safe - packages share files, so removing one means deleting what
it owns and nobody else does.

Configuration is never overwritten. Anything under `/etc` has its hash recorded
when it is installed; if the file on disk no longer matches, the incoming copy
is written as `<path>.new` and the difference reported. Files several packages
add to - `/etc/passwd` and the rest - are merged on the field
`file-policy.conf` names, the same way assembly merges them, so a package
bringing a service account does not erase the accounts already there.

`core` packages are published like any other and refuse to install into a
running system: replacing the libc underneath the processes using it is not a
transaction anything can roll back. They install with `--root` into a tree that
is then booted.

    lpkg --root /mnt/newroot install glibc

### Building on the machine itself

    lpkg build <name>            compile it here, from the channel's source package
    lpkg install --from <file>   install a package this machine built

`make repo` publishes a source package beside every binary one: the recipe and
its checksum in `src/<name>-<version>-<release>.lsrc`, and the tarball it
builds in `src/sources/`. The tarball is published beside the recipe rather
than inside it - several recipes build from one tarball and the sources run to
2.1 GB - and both are hardlinked and covered by the index signature.

A build does not overlay `/`. That would work and would make the result depend
on whatever happens to be installed on this particular machine, so a package
picks up an optional dependency here and not there. The lower layer is
materialised from a declared set instead - every core package, the toolchain
group, the recipe's own `# BUILD_REQUIRES:` transitively, and whatever provides
the sonames all of that needs - and cached under a hash of exactly that list.
The recipe then runs in a chroot over it and the upper layer becomes the
package, which is what `build-package.sh` does on the build host. One recipe,
one artifact format, two build sites.

The toolchain comes from the channel, not from this system, so a minimal
install can compile without first growing a compiler of its own. What it costs
is disk: a build root is a few gigabytes under `/var/cache/lpkg/roots`, shared
by every build resolving the same set.

Only 50 of the 234 recipes declare `# BUILD_REQUIRES:`. A build root made
purely from declarations would be empty for the rest, which is why there is a
fixed base underneath. It is worth knowing what that means: a recipe needing
something outside the base and outside its own declarations fails to find it,
rather than quietly linking whatever happened to be there.

### Testing it

    sudo make distro DISTRO=minimal REPO_URL=file:///mnt/repo
    make repo
    make test DISTRO=minimal

`make test` imports the assembled rootfs into a container and exercises lpkg
on it: that the database survived assembly, that ownership is right, that the
channel verifies against the key baked into the image rather than the one
beside the index, that core refuses to install into a running system, and that
an install and a removal do what they say. Fifteen checks, and it needs
`make repo` first because it mounts the channel into the container.

A container rather than qemu because it is the same rootfs either way and this
needs a shell in it rather than a boot. The level above answers what it cannot:

    sudo make image DISTRO=minimal
    make test-boot DISTRO=minimal

That boots a copy of the image under qemu with UEFI firmware, serves `repo/`
to the guest over http, and checks the whole path on the running system -
that it boots at all, that lpkg reads its database, that the channel verifies
over http against the key baked into the image, that core refuses to install
into a running system, and that a package downloads, installs, runs and
removes. It works on a copy, so the image `make image` produced is untouched.

Three things it has to arrange, each of which cost a wasted boot to find. The
UEFI variable store is reset, because a stale one sent the firmware to its
internal shell instead of the disk - the image was fine and never got a
chance. A serial console is added to the kernel command line, because the
image is built for a screen and a headless boot otherwise prints nothing at
all, leaving no way to tell a hang from a success. And the test waits for the
network rather than sleeping, because dhcpcd configures eth0 asynchronously
and a fixed delay raced it into reporting the channel unreachable on a system
whose networking was about to come up perfectly.

Five files show as edited on a booted system - /etc/mtab, /etc/fstab,
/etc/resolv.conf, /etc/localtime and /etc/inittab are written during boot.
That is lpkg reporting a real difference, not a fault.

It is worth running rather than trusting the scratch trees lpkg is developed
against, because those are not a system. They have no /proc, no /dev, no FHS
symlinks and only the packages somebody picked by hand, and each of those gaps
has hidden a real fault: a process substitution silently reading nothing where
/dev/fd was missing, an install reporting success having placed no files, tar
unable to decompress because gzip was not installed. The first run of this
test on a real image found that /usr/bin/awk could not start - `deps-check`
had been reporting minimal as closed while `make check` had been reporting the
truth - and that a freshly assembled image claimed 88 missing files.

Six files show as edited when the test runs: docker rewrites /etc/hosts,
/etc/hostname, /etc/resolv.conf, /etc/mtab and /etc/localtime in every
container. They match on the assembled tree, so that is lpkg correctly
reporting a real difference rather than a fault.

### Known gaps

The build base holds files that belong to no package. Chapters 5 and 6 install
the temporary toolchain into it directly, and a few things never get a recipe
of their own:

    make base-gap            what is in the base and in no package

It reports 1513 such paths, excluding `/tools` which is correctly thrown away.
The bulk is the kernel API headers - `/usr/include/linux`, `asm`,
`asm-generic`, 900 files - which come from a tools step rather than a package.
The rest that matters is small and specific: `/bin`, `/lib`, `/sbin`,
`/lib64/ld-linux-x86-64.so.2`, `/usr/bin/sh` and `/usr/include/gnu/stubs-64.h`.

`build-distro.sh` makes those by hand, so an assembled image is fine. Anything
reconstructing a root out of packages alone is not: `lpkg --root /mnt/new` and
the lower layer of `lpkg build` both come out missing them, and the symptoms
are obscure - no `/usr/bin/sh` and every configure script stops at "bad
interpreter"; no `stubs-64.h` and every compile fails in the first header; no
loader and nothing dynamically linked runs at all. A recipe installing the
kernel headers and those symlinks would close it, and `lpkg build` is blocked
on that for anything real.

Packaging is as coarse as the recipes are: `libgcc_s.so.1` lives in the gcc
package, so anything linked against it pulls in the whole compiler.

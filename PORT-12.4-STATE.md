# BLFS 11.2 -> 12.4 port: where it is and how to resume

Written mid-port so this survives losing the session that started it.

## State

Preparation is complete and verified; `make packages-lint` passes on 228
recipes. The build is running and is the only thing left.

    sudo make packages-continue          # resumes; never `make packages`

`make packages` does `rm -rf overlay/base` and would destroy the 2.6 GB of
downloaded sources. Always use `packages-continue`.

## Editing a recipe: stage it first

The chroot runs a STAGED COPY of the scripts at `$LFS_BASE/scripts`, not the
working tree. An edited recipe has no effect until:

    sudo make update-scripts

This is not optional and it fails silently - the build simply runs the old
recipe and reports whatever that does. It cost two restarts before it was
spotted. `build-package.sh` also reads `# SOURCE:` / `# VERSION:` from the
staged copy, so PKGINFO comes from there too.

## How resuming works

`tmp/<recipe>.ready` marks a package as built. The LFS flags are intact, so
LFS is skipped entirely - nothing in it changed and glibc 2.42 / gcc 15.2.0
stay as they were. The BLFS flags for every bumped or edited recipe were
cleared, which is what makes them rebuild.

After fixing a failing recipe:

    sudo rm -f tmp/<recipe>.ready
    sudo make packages-continue

The build stops at the first failing recipe. Its log is at
`overlay/package/tmp/<recipe>.log` (root-owned).

## ABI

    c3142651facf     the new scheme, and what the port produces

`abi-id.sh` was re-keyed during this port: glibc and gcc by version (symbol
versions are not expressible as a soname), everything else by soname set. The
live core computes to the same value, so this port does NOT change the
channel - Berkeley DB was kept in core deliberately for that reason.

The machine at 192.168.1.161 carries `ABI_ID=2d3f09c6c5c6` in
`/etc/os-release`, which the OLD scheme produced for that same core. It needs
that line changed to `c3142651facf` to read the new channel; it does not need
a reimage.

## After the build

    make packages-meta                   # refresh the index from the new packages
    ./scripts/packages/abi-id.sh         # confirm it is still c3142651facf
    make repo                            # publish the channel locally
    make channels                        # the channel directory
    make publish                         # upload to R2

Confirm the built curl kept `libcurl.so.4`; the predicted ABI depends on it.

## What changed in the port

- 105 version bumps, driven from BLFS-BOOK-12.4-nochunks.html
- dropped: mandoc, unzip, mesa-demos, atk, at-spi2-atk, reiserfsprogs, pcre,
  wireless-regdb, python310, 2-blfs-bootscripts
- added: pcre2, libnotify, startup-notification
- kept deliberately: db (holds libdb-5.3.so in the core soname set)
- 4 autotools -> meson rewrites: cairo, dbus, usbutils, glu
- 3 xorg meta lists regenerated: 32 libraries, 33 apps, 9 fonts
- unzip replaced by bsdtar in docbook-xml and sqlite
- firefox 140 recipe rewritten; three 102-era workarounds retired
- `.env` BLFS_VER=12.4; new sources/blfs-12.4.{wget-list,md5sums,extra-list}
- superseded 11.2 tarballs parked in overlay/base/sources-11.2/

## Not yet done

- the build
- publishing
- migrating .161
- nothing is committed; `git status` is the full diff

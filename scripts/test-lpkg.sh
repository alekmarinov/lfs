#!/bin/bash
# Exercises lpkg against a real assembled distro, in a container.
#
#   test-lpkg.sh [<distro>]
#
# The scratch trees lpkg is developed against are not a system: they have no
# /proc, no /dev, no FHS symlinks, and only the packages somebody picked by
# hand. Every one of those gaps has hidden a real bug at some point - a
# process substitution silently reading nothing without /dev/fd, an install
# reporting success having placed no files, tar unable to decompress because
# gzip was not installed. So the test that matters runs on a tree that
# build-distro.sh assembled and a kernel would boot.
#
# Docker rather than qemu because it is the same rootfs either way, and this
# needs a shell in it rather than a boot. 'make qemu' is the level above:
# whether it boots, which this cannot answer.
#
# What it checks, in order of what would hurt most if it broke:
#
#   the database survived assembly     - a fresh image which believes nothing
#                                        is installed can upgrade nothing, and
#                                        anything it installs claims files it
#                                        does not own
#   ownership is right                 - removal depends on it entirely
#   the channel verifies               - against the key baked into the image,
#                                        not the one sitting beside the index
#   install, remove and their guards   - including that core refuses to go
#                                        into a running system
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/.." &> /dev/null && pwd )
cd "$BASE_DIR"

DISTRO="${1:-minimal}"
OUT=$("$BASE_DIR/scripts/resolve-distro.sh" -o "$DISTRO")
ROOTFS="$OUT/rootfs"
TAG="lpkg-test"

[ -d "$ROOTFS" ] || {
    echo "No rootfs at $ROOTFS - run 'make distro DISTRO=$DISTRO' first"
    exit 1
}
command -v docker > /dev/null || { echo "docker is not installed"; exit 1; }

ABI=$(sed -n 's/^ABI_ID=//p' "$ROOTFS/etc/os-release" 2>/dev/null)
[ -n "$ABI" ] || { echo "$ROOTFS/etc/os-release carries no ABI_ID"; exit 1; }
CHANNEL="repo/$ABI/x86_64"
[ -d "$CHANNEL" ] || { echo "No channel for this rootfs at $CHANNEL - run 'make repo'"; exit 1; }

echo "Testing $DISTRO (ABI $ABI)"

# The image is imported from the tree rather than built from a Dockerfile, so
# what is tested is exactly what was assembled.
echo "Importing the rootfs..."
# Checked, rather than assumed. Without this every case below failed with
# docker's usage message and reported fifteen distinct assertion failures for
# one broken import.
if ! sudo tar -C "$ROOTFS" -cf - . 2>/dev/null | docker import - "$TAG" > /dev/null; then
    echo "could not import $ROOTFS into docker"
    exit 1
fi
docker image inspect "$TAG" > /dev/null 2>&1 || { echo "the image did not appear after import"; exit 1; }

pass=0; fail=0
check() {
    local what="$1" expect="$2" got="$3"
    if [ "$got" = "$expect" ]; then
        printf '  ok    %s\n' "$what"; pass=$((pass + 1))
    else
        printf '  FAIL  %s\n        expected: %s\n        got:      %s\n' "$what" "$expect" "$got"
        fail=$((fail + 1))
    fi
}
# runs a command in the container, with the channel mounted where the config says
run() {
    docker run --rm -v "$BASE_DIR/repo:/mnt/repo:ro" "$TAG" /usr/bin/lpkg "$@" 2>&1
}
# same, but keeps the container so a later step sees the change
run_in() {
    docker run --rm -v "$BASE_DIR/repo:/mnt/repo:ro" "$TAG" /bin/bash -c "$1" 2>&1
}

echo
echo "the package manager itself"
check "lpkg runs"            "0" "$(run version > /dev/null; echo $?)"
check "it reports a version" "yes" "$(run version | grep -q '^lpkg ' && echo yes || echo no)"

echo
echo "the database assembly left behind"
n=$(run list | wc -l)
check "packages are recorded"  "yes" "$([ "$n" -gt 40 ] && echo yes || echo no)"
echo "        ($n packages in the database)"
check "lpkg records itself"    "yes" "$(run list | grep -q '^lpkg ' && echo yes || echo no)"
check "glibc is recorded"      "yes" "$(run list | grep -q '^glibc ' && echo yes || echo no)"

echo
echo "ownership"
check "bash owns its binary"   "yes" "$(run owns /usr/bin/bash | grep -q 'owned by bash' && echo yes || echo no)"
check "lpkg owns its own"      "yes" "$(run owns /usr/bin/lpkg | grep -q 'owned by lpkg' && echo yes || echo no)"
check "an unowned path says so" "1" "$(run owns /etc/definitely-not-a-package > /dev/null 2>&1; echo $?)"

echo
echo "what is on disk matches what was recorded"
v=$(run verify 2>&1 | tail -1)
check "nothing is missing"     "yes" "$(echo "$v" | grep -q '^0 missing' && echo yes || echo no)"
echo "        ($v)"

echo
echo "the channel"
s=$(run_in 'printf "REPO_URL=file:///mnt/repo\n" > /etc/lpkg/lpkg.conf; lpkg sync' | tail -2)
check "index verifies against the baked-in key" "yes" \
    "$(echo "$s" | grep -q 'signature ok' && echo yes || echo no)"
check "and the ABI matches"    "yes" "$(echo "$s" | grep -q 'packages in channel' && echo yes || echo no)"

echo
echo "guards"
c=$(run_in 'printf "REPO_URL=file:///mnt/repo\n" > /etc/lpkg/lpkg.conf; lpkg sync >/dev/null; lpkg --yes --reinstall install glibc')
check "core refuses a live install" "yes" \
    "$(echo "$c" | grep -q 'cannot be installed into a running system' && echo yes || echo no)"
r=$(run_in 'lpkg remove glibc')
check "a needed package refuses removal" "yes" \
    "$(echo "$r" | grep -q 'still needed' && echo yes || echo no)"

echo
echo "a real install and removal"
i=$(run_in 'printf "REPO_URL=file:///mnt/repo\n" > /etc/lpkg/lpkg.conf
            lpkg sync >/dev/null
            lpkg --yes install which >/dev/null 2>&1
            command -v which && lpkg owns /usr/bin/which')
check "an installed program is there and owned" "yes" \
    "$(echo "$i" | grep -q 'owned by which' && echo yes || echo no)"
d=$(run_in 'printf "REPO_URL=file:///mnt/repo\n" > /etc/lpkg/lpkg.conf
            lpkg sync >/dev/null
            lpkg --yes install which >/dev/null 2>&1
            lpkg --yes remove which >/dev/null 2>&1
            test -e /usr/bin/which && echo still-there || echo gone')
check "and gone after removal" "gone" "$(echo "$d" | tail -1)"

echo
docker rmi "$TAG" > /dev/null 2>&1 || true
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1

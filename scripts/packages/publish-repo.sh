#!/bin/bash
# Uploads the published channel to the R2 bucket behind lfs.intelibo.com.
#
#   publish-repo.sh [--dry-run] [--delete]
#
# 'make repo' builds repo/<abi>/<arch>/ locally; this puts it where the world
# can reach it. The layout is identical either way, so nothing is rearranged
# and REPO_URL is just the bucket's hostname.
#
# Almost everything here is immutable. A package file is named
# name-version-release.arch.lpkg and its contents never change under that
# name - a rebuild that changes anything changes the release. So after the
# first upload a publish moves the index and whatever was rebuilt, and nothing
# else: kilobytes, not gigabytes.
#
# That immutability is also why the cache headers are split. The packages are
# told to cache for a year; INDEX and its signature are told not to cache at
# all. Getting that backwards is the failure this is most likely to have:
# a system resolves against a stale index, asks for a package the channel no
# longer lists, and the error it reports is a 404 rather than the truth.
#
# CREDENTIALS
#
# An R2 API token, not a Cloudflare API token - they are different things.
# Create it under R2 > Manage API tokens with Object Read & Write, and export:
#
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   export R2_ACCOUNT_ID=...        # or let terraform output supply it
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$( cd -- "$SCRIPT_DIR/../.." &> /dev/null && pwd )
cd "$BASE_DIR"

BUCKET="${R2_BUCKET:-lfs-packages}"
dry=""
delete=""
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) dry="--dryrun"; shift ;;
        # Off by default. Removing an object the local tree no longer has is
        # usually right, and is occasionally how a channel loses the package
        # an installed system is still pinned to.
        --delete)  delete="--delete"; shift ;;
        *) echo "unknown argument $1"; exit 1 ;;
    esac
done

# Credentials come from the environment, or from a file beside the signing
# key. Not from .env in this tree: that one is tracked by git and included by
# the Makefile, so a token there would be committed and exported to every
# build. Under sudo $HOME is /root, so the invoking user's home is tried too.
CREDS="${LFS_CLOUDFLARE_ENV:-$HOME/.config/lfs/cloudflare.env}"
if [ ! -f "$CREDS" ] && [ -n "${SUDO_USER:-}" ]; then
    CREDS="$(getent passwd "$SUDO_USER" | cut -d: -f6)/.config/lfs/cloudflare.env"
fi
if [ -z "${AWS_ACCESS_KEY_ID:-}" ] && [ -f "$CREDS" ]; then
    # read, not sourced: it is a credentials file, and sourcing it would let
    # it run anything
    while IFS='=' read -r k v; do
        case "$k" in
            AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|R2_ACCOUNT_ID|R2_BUCKET|R2_HOSTNAME)
                [ -n "$v" ] && export "$k=$v" ;;
        esac
    done < "$CREDS"
fi

command -v aws > /dev/null || { echo "the aws cli is needed to talk to R2"; exit 1; }
[ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ] \
    || { echo "No R2 credentials. Fill in $CREDS, or export"
         echo "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from an R2 API token."; exit 1; }

ACCOUNT="${R2_ACCOUNT_ID:-}"
if [ -z "$ACCOUNT" ] && [ -d infra ]; then
    ACCOUNT=$(terraform -chdir=infra output -raw account_id 2>/dev/null || true)
fi
[ -n "$ACCOUNT" ] || { echo "set R2_ACCOUNT_ID, or run terraform in infra/ first"; exit 1; }
ENDPOINT="https://$ACCOUNT.r2.cloudflarestorage.com"

ABI=$("$SCRIPT_DIR/abi-id.sh")
ARCH="${PKG_ARCH:-x86_64}"
REPO_ROOT="repo"
CHANNEL="$REPO_ROOT/$ABI/$ARCH"
[ -d "$CHANNEL" ] || { echo "No channel at $CHANNEL - run 'make repo' first"; exit 1; }

# Refusing to publish a channel that does not check out locally. It costs
# seconds and the alternative is discovering a bad signature from a machine
# that has already stopped trusting the repository.
echo "Checking the channel before uploading it..."
"$SCRIPT_DIR/verify-repo.sh" "$CHANNEL" --quick > /dev/null \
    || { echo "the channel does not verify locally; not publishing it"; exit 1; }

s3() { aws s3 --endpoint-url "$ENDPOINT" "$@"; }

echo "Publishing $CHANNEL to s3://$BUCKET/$ABI/$ARCH"

# 1. the packages and sources first, cached hard.
#
# Before the index, always. A system that syncs midway through a publish then
# sees the old index, which names only objects that are already there - the
# worst it gets is an out of date channel. The other order gives it an index
# naming packages that have not finished uploading.
s3 sync "$CHANNEL" "s3://$BUCKET/$ABI/$ARCH" $dry $delete \
    --exclude 'INDEX' --exclude 'INDEX.sig' --exclude 'INDEX.pub' \
    --cache-control 'public, max-age=31536000, immutable' \
    --no-progress

# 2. then the index, which must never be served stale.
s3 cp "$CHANNEL/INDEX"     "s3://$BUCKET/$ABI/$ARCH/INDEX"     $dry \
    --cache-control 'no-cache, must-revalidate' --content-type 'text/plain'
[ -f "$CHANNEL/INDEX.sig" ] && s3 cp "$CHANNEL/INDEX.sig" "s3://$BUCKET/$ABI/$ARCH/INDEX.sig" $dry \
    --cache-control 'no-cache, must-revalidate' --content-type 'application/octet-stream'

# 3. and the channel directory at the bucket root, also never stale.
#
# At the root, not inside the channel: the system that most needs it is one
# whose own channel has been superseded, and it has no reason to look inside a
# channel it can no longer use.
if [ -f "$REPO_ROOT/channels" ]; then
    s3 cp "$REPO_ROOT/channels" "s3://$BUCKET/channels" $dry \
        --cache-control 'no-cache, must-revalidate' --content-type 'text/plain'
    [ -f "$REPO_ROOT/channels.sig" ] && s3 cp "$REPO_ROOT/channels.sig" "s3://$BUCKET/channels.sig" $dry \
        --cache-control 'no-cache, must-revalidate' --content-type 'application/octet-stream'
else
    echo "  no channel directory to publish - run 'make channels'"
fi

echo
echo "Published. On a target:"
echo "    REPO_URL=https://${R2_HOSTNAME:-lfs.intelibo.com}"
echo "and the channel it will read is $ABI/$ARCH."
echo
echo "INDEX.pub is deliberately not uploaded: a key served from the channel it"
echo "verifies proves nothing. build-distro.sh bakes it into the image instead."

# Hosting the package channel

The repository is static files, so it needs object storage and a name. This
creates both: an R2 bucket, and `lfs.intelibo.com` bound to it.

    cd infra
    export CLOUDFLARE_API_TOKEN=...
    terraform init && terraform apply

Then, from the top of the tree:

    make repo        # build and sign the channel locally
    make publish     # upload it

## The two tokens

They are different things and are easy to confuse.

**A Cloudflare API token**, for terraform. Create it at *My Profile > API
Tokens* with:

| Scope | Permission | Why |
|---|---|---|
| Account | Workers R2 Storage: Edit | create the bucket |
| Zone (intelibo.com) | Zone: Read | look the zone id up by name |
| Zone (intelibo.com) | DNS: Edit | Cloudflare writes the record for the custom domain |

**An R2 API token**, for uploads. A separate credential, created at *R2 >
Manage API tokens* with Object Read & Write. It gives an access key and secret
which the S3 protocol expects:

    export AWS_ACCESS_KEY_ID=...
    export AWS_SECRET_ACCESS_KEY=...

## What is deliberately not here

**The DNS record.** Binding a custom domain to a bucket makes Cloudflare
create and own that record, and it must be proxied for R2 to serve it.
Declaring a `cloudflare_dns_record` for the same name would leave terraform
and the R2 API fighting over it, and the symptom is a record that flips on
every apply.

**The signing key's public half.** `INDEX.pub` is not uploaded. A key served
from the channel it is supposed to verify proves only that whoever wrote the
index also wrote the key beside it. `build-distro.sh` bakes it into the image,
which is the only path that means anything.

**The token.** The provider reads `CLOUDFLARE_API_TOKEN` from the environment
rather than a variable, because a variable ends up in a `.tfvars` file and a
`.tfvars` file ends up committed. `.env` in this tree is already tracked with
a root password in it, which is the argument.

## Cost

The free tier is 10 GB of storage, and **egress is not charged** - which is
what makes R2 the right answer rather than merely a cheap one. Installing
Firefox pulls about 150 MB, so a channel on metered bandwidth bills per
machine that uses it.

Stripped, the binary channel is roughly 1 GB and the sources 1.5 GB. That
leaves room for a second ABI, but not an unbounded number of them: a rebuilt
glibc creates a new channel and the old one keeps its packages. Prune the
channels no live system is pinned to.

## Where the ABI fits in

The bucket holds one directory per ABI:

    lfs.intelibo.com/<abi-id>/x86_64/INDEX

`lpkg` builds that path from the `ABI_ID` in its own `/etc/os-release`, so a
system can only ever reach the channel built for the core it is running. That
is why `REPO_URL` is just the hostname, with no channel in it.

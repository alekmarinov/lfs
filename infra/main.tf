# The package repository's hosting: an R2 bucket served at lfs.intelibo.com.
#
# A channel is static files - an index, a signature and the packages - so it
# needs object storage and a name, and nothing else. No server, no TLS to
# renew, no disk to fill.
#
# R2 rather than any other free tier for one reason: egress is not charged.
# Installing Firefox pulls about 150 MB, and a repository that charges for
# bandwidth bills per machine that uses it.
#
#   cd infra
#   export CLOUDFLARE_API_TOKEN=...   # see README.md for the scopes
#   terraform init && terraform apply
#
# The DNS record for the custom domain is not declared here. Cloudflare
# creates and owns it as part of binding the domain to the bucket, and it has
# to be proxied for R2 to serve it - declaring it separately would fight the
# API for control of the same record.

terraform {
  required_version = ">= 1.5"
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      # v5 is a rewrite generated from the API schema; the resource names and
      # arguments below are v5's and do not exist in v4.
      version = "~> 5.0"
    }
  }
}

# Reads CLOUDFLARE_API_TOKEN from the environment. Deliberately not a variable:
# a token in a .tfvars file is a token in a repository sooner or later, and
# .env in this tree is already committed with a root password in it.
provider "cloudflare" {}

variable "zone_name" {
  description = "The domain already on Cloudflare that the channel lives under."
  type        = string
  default     = "intelibo.com"
}

variable "hostname" {
  description = "Where the channel is served. This becomes REPO_URL for lpkg."
  type        = string
  default     = "lfs.intelibo.com"
}

variable "bucket_name" {
  description = "R2 bucket holding the channel."
  type        = string
  default     = "lfs-packages"
}

variable "location" {
  description = <<-EOT
    Where R2 keeps the objects: weur, eeur, enam, wnam, apac, oc.
    A hint, not a guarantee, and it only affects where writes land - reads are
    served from Cloudflare's edge wherever the reader is.
  EOT
  type        = string
  default     = "weur"
}

data "cloudflare_zone" "this" {
  # An attribute, not a block. The v5 provider is generated from the API
  # schema and models nested objects as attributes, so the block form the
  # published example still shows is rejected.
  filter = {
    name = var.zone_name
  }
}

resource "cloudflare_r2_bucket" "channel" {
  account_id = data.cloudflare_zone.this.account.id
  name       = var.bucket_name
  location   = var.location

  # Standard, not InfrequentAccess. IA is cheaper to store and charges for
  # retrieval, which is the wrong way round here: the packages are written
  # once and read by every machine that installs anything.
  storage_class = "Standard"
}

resource "cloudflare_r2_custom_domain" "channel" {
  account_id  = data.cloudflare_zone.this.account.id
  zone_id     = data.cloudflare_zone.this.id
  bucket_name = cloudflare_r2_bucket.channel.name
  domain      = var.hostname
  enabled     = true

  # 1.2 is the floor worth serving. lpkg verifies the index signature itself,
  # so transport security is not what makes the channel trustworthy - but
  # there is no reason to accept a downgrade either.
  min_tls = "1.2"
}

output "repo_url" {
  description = "Put this in /etc/lpkg/lpkg.conf on a target, or pass REPO_URL to make distro."
  value       = "https://${var.hostname}"
}

output "bucket" {
  description = "Bucket name, for rclone and the aws cli."
  value       = cloudflare_r2_bucket.channel.name
}

output "account_id" {
  description = "Needed to build the S3 endpoint for uploads."
  value       = data.cloudflare_zone.this.account.id
}

output "s3_endpoint" {
  description = "S3-compatible endpoint 'make publish' uploads to."
  value       = "https://${data.cloudflare_zone.this.account.id}.r2.cloudflarestorage.com"
}

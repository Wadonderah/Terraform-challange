##############################################################################
# Day 14 — Working with Multiple Providers (Multi-Region)
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya / EveOps
##############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # ~> 5.0 means: >= 5.0.0 AND < 6.0.0
      # This allows patch and minor updates but blocks major version bumps
      # that would contain breaking changes.
    }
  }
}

##############################################################################
# PROVIDER CONFIGURATIONS
##############################################################################

# Default provider — us-east-1
# Any resource that does NOT specify a provider = argument uses this one.
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = "30DayTerraformChallenge"
      Day         = "14"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Aliased provider — us-west-2
# Resources that specify provider = aws.replica use this configuration.
# Terraform will call us-west-2 API endpoints for those resources.
provider "aws" {
  alias  = "replica"
  region = var.replica_region

  default_tags {
    tags = {
      Project     = "30DayTerraformChallenge"
      Day         = "14"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Role        = "Replica"
    }
  }
}

##############################################################################
# DATA SOURCES — Current Account Identity
##############################################################################

data "aws_caller_identity" "current" {}
data "aws_caller_identity" "replica" {
  provider = aws.replica
}

##############################################################################
# IAM — S3 Replication Role
##############################################################################

data "aws_iam_policy_document" "replication_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "replication" {
  name               = "${var.project_prefix}-s3-replication-role"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json

  tags = {
    Name = "${var.project_prefix}-s3-replication-role"
  }
}

data "aws_iam_policy_document" "replication_policy" {
  statement {
    sid    = "AllowSourceBucketRead"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.primary.arn]
  }

  statement {
    sid    = "AllowSourceObjectRead"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.primary.arn}/*"]
  }

  statement {
    sid    = "AllowDestinationWrite"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${aws_s3_bucket.replica.arn}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  name   = "${var.project_prefix}-s3-replication-policy"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication_policy.json
}

##############################################################################
# PRIMARY BUCKET — us-east-1 (default provider)
# Terraform calls the us-east-1 S3 endpoint for this resource.
##############################################################################

resource "aws_s3_bucket" "primary" {
  # No provider argument → uses the default provider (us-east-1)
  bucket = "${var.project_prefix}-primary-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name   = "${var.project_prefix}-primary"
    Region = var.primary_region
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  bucket                  = aws_s3_bucket.primary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##############################################################################
# REPLICA BUCKET — us-west-2 (aliased provider)
# Terraform calls the us-west-2 S3 endpoint for this resource.
##############################################################################

resource "aws_s3_bucket" "replica" {
  # Explicit provider reference → Terraform uses aws.replica configuration
  provider = aws.replica
  bucket   = "${var.project_prefix}-replica-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name   = "${var.project_prefix}-replica"
    Region = var.replica_region
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  provider                = aws.replica
  bucket                  = aws_s3_bucket.replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##############################################################################
# S3 REPLICATION CONFIGURATION
# Must be set up after versioning is enabled on both buckets.
##############################################################################

resource "aws_s3_bucket_replication_configuration" "primary_to_replica" {
  # This resource lives in the primary region (default provider)
  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica,
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all-objects"
    status = "Enabled"

    filter {
      prefix = "" # Replicate all objects
    }

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA" # Cost-optimised for replica storage
      # No encryption_configuration block needed here — the replica bucket
      # already has AES-256 SSE-S3 applied via its own encryption resource.
      # encryption_configuration is only required when using SSE-KMS (a CMK).
    }
  }
}

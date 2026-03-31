# modules/multi-region-app/main.tf
# -----------------------------------------------------------------------------
# Multi-Region S3 Replication Module
#
# IMPORTANT: No provider blocks are defined here.
# Modules that rely on aliased providers CANNOT declare their own provider
# blocks. Doing so would force every caller to use the same region/account,
# defeating the entire purpose of aliases. Instead, the module declares which
# provider aliases it EXPECTS via configuration_aliases, and the root module
# passes the real providers in through the `providers` map.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"

      # configuration_aliases tells Terraform:
      # "This module does NOT create these providers — the caller must supply them."
      # Without this block, Terraform would reject a `provider = aws.primary`
      # reference inside a module because it would have no idea that alias exists.
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}

# ---------------------------------------------------------------------------
# Primary-region bucket (us-east-1 in the calling configuration)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${var.app_name}-primary-${var.environment}"

  tags = merge(var.common_tags, {
    Role   = "primary"
    Region = "us-east-1"
  })
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# Replica-region bucket (us-west-2 in the calling configuration)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "${var.app_name}-replica-${var.environment}"

  tags = merge(var.common_tags, {
    Role   = "replica"
    Region = "us-west-2"
  })
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
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# Replication IAM role (lives in primary region/account)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "replication_assume_role" {
  provider = aws.primary

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
  provider           = aws.primary
  name               = "${var.app_name}-s3-replication-role"
  assume_role_policy = data.aws_iam_policy_document.replication_assume_role.json

  tags = var.common_tags
}

data "aws_iam_policy_document" "replication" {
  provider = aws.primary

  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.primary.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.primary.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateDeleteMarkers",
    ]

    resources = ["${aws_s3_bucket.replica.arn}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.primary
  name     = "${var.app_name}-s3-replication-policy"
  role     = aws_iam_role.replication.id
  policy   = data.aws_iam_policy_document.replication.json
}

# ---------------------------------------------------------------------------
# Cross-region replication configuration
# Both buckets must have versioning enabled before this can be applied.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "primary_to_replica" {
  provider = aws.primary

  # Replication depends on versioning being enabled on both buckets
  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica,
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all-objects"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }
}

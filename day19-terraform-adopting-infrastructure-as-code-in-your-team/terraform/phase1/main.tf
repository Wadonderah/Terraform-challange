################################################################################
# Phase 1 — Start with something new
#
# First rule of IaC adoption: don't touch existing infrastructure.
# Pick something brand new, provision it cleanly, let the team see the workflow.
# This is a CloudTrail log bucket. Low stakes. High visibility. Perfect first PR.
#
# Author: Day 19 — 30-Day Terraform Challenge
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Temporary: comment out S3 backend to avoid 403
  # backend "s3" {
  #   bucket         = "acme-terraform-state"
  #   key            = "cloudtrail/terraform.tfstate"
  #   region         = "af-south-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }

  # Local backend to use while S3 access fails

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region  = "us-east-1" # match your CLI default
  profile = "default"   # force Terraform to use CLI credentials

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = var.environment
      Project     = "cloudtrail-logging-v3"
      Owner       = "platform-team"
    }
  }
}

###############################################################################
# S3 bucket for CloudTrail logs
# Nothing fancy. Versioning on, public access blocked, lifecycle rule to keep
# costs sane. This is the kind of resource that gets created manually, forgotten,
# and never cleaned up. Not anymore.
###############################################################################

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "acme-cloudtrail-logs-${var.environment}"
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {} # <-- Add this line for Terraform 5.x compatibility

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    # Old rule (without filter) - commented out
    # transition {
    #   days          = 30
    #   storage_class = "STANDARD_IA"
    # }
    # transition {
    #   days          = 90
    #   storage_class = "GLACIER"
    # }
    # expiration {
    #   days = 365
    # }
  }
}

# Bucket policy: allow CloudTrail to write, nothing else

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

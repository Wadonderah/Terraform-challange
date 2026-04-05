##############################################################################
# Day 14 — Multi-Account Provider Configuration
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya / EveOps
#
# USAGE:
#   1. Replace the role ARNs with real ARNs in your accounts.
#   2. Ensure the executing identity can call sts:AssumeRole on each role.
#   3. Run: terraform init && terraform plan
##############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

##############################################################################
# MULTI-ACCOUNT PROVIDER CONFIGURATIONS
#
# Each provider block assumes a different IAM role in a different account.
# Terraform authenticates with your local credentials (or CI role), then
# calls sts:AssumeRole to obtain short-lived credentials for each account.
##############################################################################

# Production account provider
provider "aws" {
  alias  = "production"
  region = var.primary_region

  assume_role {
    # Replace with your production account role ARN
    role_arn         = "arn:aws:iam::${var.production_account_id}:role/TerraformDeployRole"
    session_name     = "terraform-day14-prod"
    duration_seconds = 3600

    # Optional: tag the assumed session for CloudTrail auditing
    tags = {
      ManagedBy = "Terraform"
      Day       = "14"
    }
  }

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}

# Staging account provider
provider "aws" {
  alias  = "staging"
  region = var.primary_region

  assume_role {
    # Replace with your staging account role ARN
    role_arn         = "arn:aws:iam::${var.staging_account_id}:role/TerraformDeployRole"
    session_name     = "terraform-day14-staging"
    duration_seconds = 3600

    tags = {
      ManagedBy = "Terraform"
      Day       = "14"
    }
  }

  default_tags {
    tags = {
      Environment = "staging"
      ManagedBy   = "Terraform"
    }
  }
}

##############################################################################
# EXAMPLE RESOURCES — One in each account
##############################################################################

# S3 bucket in production account
resource "aws_s3_bucket" "prod_config" {
  provider = aws.production
  bucket   = "${var.project_prefix}-config-prod-${var.production_account_id}"

  tags = {
    Name    = "${var.project_prefix}-config-prod"
    Account = var.production_account_id
  }
}

# S3 bucket in staging account
resource "aws_s3_bucket" "staging_config" {
  provider = aws.staging
  bucket   = "${var.project_prefix}-config-staging-${var.staging_account_id}"

  tags = {
    Name    = "${var.project_prefix}-config-staging"
    Account = var.staging_account_id
  }
}

##############################################################################
# DATA SOURCES — Verify which account each provider resolved to
##############################################################################

data "aws_caller_identity" "production" {
  provider = aws.production
}

data "aws_caller_identity" "staging" {
  provider = aws.staging
}

##############################################################################
# OUTPUTS
##############################################################################

output "production_account_resolved" {
  description = "Account ID Terraform resolved for the production provider"
  value       = data.aws_caller_identity.production.account_id
}

output "staging_account_resolved" {
  description = "Account ID Terraform resolved for the staging provider"
  value       = data.aws_caller_identity.staging.account_id
}

##############################################################################
# VARIABLES
##############################################################################

variable "primary_region" {
  description = "AWS region used by both accounts"
  type        = string
  default     = "us-east-1"
}

variable "production_account_id" {
  description = "12-digit AWS account ID for production"
  type        = string
  # Example: "111111111111"
}

variable "staging_account_id" {
  description = "12-digit AWS account ID for staging"
  type        = string
  # Example: "222222222222"
}

variable "project_prefix" {
  description = "Short prefix for all resource names"
  type        = string
  default     = "tf-challenge-day14"
}

##############################################################################
# REQUIRED IAM PERMISSIONS FOR TerraformDeployRole
#
# Trust policy (who can assume this role):
# {
#   "Version": "2012-10-17",
#   "Statement": [{
#     "Effect": "Allow",
#     "Principal": {
#       "AWS": "arn:aws:iam::<MANAGEMENT-ACCOUNT-ID>:root"
#     },
#     "Action": "sts:AssumeRole",
#     "Condition": {
#       "StringEquals": {
#         "sts:ExternalId": "terraform-deploy"
#       }
#     }
#   }]
# }
#
# Permission policy (what this role can do):
# For demo purposes — scope down for production use:
# {
#   "Version": "2012-10-17",
#   "Statement": [{
#     "Effect": "Allow",
#     "Action": [
#       "s3:CreateBucket",
#       "s3:DeleteBucket",
#       "s3:GetBucketPolicy",
#       "s3:PutBucketPolicy",
#       "s3:GetBucketTagging",
#       "s3:PutBucketTagging",
#       "s3:GetEncryptionConfiguration",
#       "s3:PutEncryptionConfiguration",
#       "s3:GetBucketPublicAccessBlock",
#       "s3:PutBucketPublicAccessBlock"
#     ],
#     "Resource": "*"
#   }]
# }
##############################################################################

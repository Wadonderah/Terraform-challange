# envs/dev/main.tf
# Dev environment — cheap, fast, destructible.
# All complexity lives in the module. This file stays clean.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "wadondera-tfstate-bucket-123"
    key            = "day25/static-website/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = "dev"
      Project     = "static-website"
      Challenge   = "30DayTerraformChallenge"
    }
  }
}

module "static_website" {
  source = "../../modules/s3-static-website"

  bucket_name         = var.bucket_name
  environment         = var.environment
  project_name        = var.project_name
  website_title       = var.website_title
  website_description = var.website_description
  index_document      = var.index_document
  error_document      = var.error_document

  # Dev-specific: cheapest price class, short TTL for rapid iteration
  cloudfront_price_class = "PriceClass_100"
  default_ttl            = 60    # 1 minute — see content changes quickly
  max_ttl                = 300   # 5 minutes max in dev

  # Dev: allow destroy even with content in bucket
  force_destroy     = true
  enable_versioning = false

  # No custom domain in dev — use CloudFront domain directly
  domain_name = null

  tags = {
    Owner = "terraform-challenge"
    Day   = "25"
  }
}

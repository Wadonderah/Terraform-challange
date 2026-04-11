# envs/prod/main.tf
# Production — hardened. Global CDN. Versioning on. Deletion protection.
# ACM certificate and Route53 custom domain ready to activate.

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
    key            = "day25/static-website/prod/terraform.tfstate"
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
      Environment = "production"
      Project     = "static-website"
      Challenge   = "30DayTerraformChallenge"
    }
  }
}

module "static_website" {
  source = "../../modules/s3-static-website"

  bucket_name         = var.bucket_name
  environment         = "production"
  project_name        = var.project_name
  website_title       = var.website_title
  website_description = var.website_description

  # Production: all edge locations, long cache, maximum performance
  cloudfront_price_class = "PriceClass_All"
  default_ttl            = 86400    # 24 hours
  max_ttl                = 604800   # 7 days

  # Production: NEVER allow destroying non-empty bucket
  force_destroy     = false
  enable_versioning = true

  # Production: custom domain (uncomment and fill in when ready)
  domain_name          = var.domain_name
  route53_zone_id      = var.route53_zone_id
  acm_certificate_arn  = var.acm_certificate_arn

  # Production: enable access logging
  log_bucket_name = var.log_bucket_name

  tags = {
    Owner      = "platform-team"
    CostCenter = "infrastructure"
    Day        = "25"
  }
}

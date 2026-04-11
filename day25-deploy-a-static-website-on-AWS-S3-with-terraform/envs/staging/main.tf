# envs/staging/main.tf

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
    key            = "day25/static-website/staging/terraform.tfstate"
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
      Environment = "staging"
      Project     = "static-website"
      Challenge   = "30DayTerraformChallenge"
    }
  }
}

module "static_website" {
  source = "../../modules/s3-static-website"

  bucket_name         = var.bucket_name
  environment         = "staging"
  project_name        = var.project_name
  website_title       = var.website_title
  website_description = var.website_description

  # Staging: wider distribution, longer TTL — closer to production behaviour
  cloudfront_price_class = "PriceClass_200"
  default_ttl            = 3600    # 1 hour
  max_ttl                = 86400   # 24 hours

  force_destroy     = true    # still destroyable — not production
  enable_versioning = true    # enabled to mirror production behaviour

  domain_name = var.domain_name    # optional staging subdomain

  tags = {
    Owner = "terraform-challenge"
    Day   = "25"
  }
}

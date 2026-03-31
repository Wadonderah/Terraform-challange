# live/multi-region/main.tf
# -----------------------------------------------------------------------------
# Root configuration: Multi-Region S3 deployment
#
# This file owns the provider blocks. Each aliased provider maps to one
# AWS region. The `providers` map in the module call wires these aliased
# providers to the configuration_aliases the module declared.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Recommended: store state remotely so the team can collaborate.
  # Uncomment and fill in your bucket/table names before running.
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "day15/multi-region/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# ---------------------------------------------------------------------------
# Provider aliases — the root module is the ONLY place these are declared.
# ---------------------------------------------------------------------------

provider "aws" {
  alias  = "primary"
  region = var.primary_region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "replica"
  region = var.replica_region

  default_tags {
    tags = local.common_tags
  }
}

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  common_tags = {
    Project     = "30DayTerraformChallenge"
    Day         = "15"
    ManagedBy   = "Terraform"
    Environment = var.environment
    Owner       = "AWSUserGroupKenya"
  }
}

# ---------------------------------------------------------------------------
# Module call — wire aliases into the module via the `providers` map.
#
# The left-hand side of each entry (aws.primary / aws.replica) must match
# the configuration_aliases declared in the module's required_providers block.
# The right-hand side references the aliased providers defined above.
# ---------------------------------------------------------------------------

module "multi_region_app" {
  source = "../../modules/multi-region-app"

  app_name    = var.app_name
  environment = var.environment
  common_tags = local.common_tags

  # This is the critical wiring. Without the `providers` map, Terraform would
  # not know which aliased provider to inject for aws.primary / aws.replica
  # inside the module, and the plan would fail with an "unknown provider" error.
  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}

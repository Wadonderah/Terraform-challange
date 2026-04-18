terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ── Primary region ────────────────────────────────────────────────────────────
provider "aws" {
  alias  = "primary"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "multi-region-ha"
      ManagedBy = "terraform"
      Challenge = "30-day-terraform"
      Owner     = "Wadonderah"
    }
  }
}

# ── Secondary region ──────────────────────────────────────────────────────────
provider "aws" {
  alias  = "secondary"
  region = "us-west-2"

  default_tags {
    tags = {
      Project   = "multi-region-ha"
      ManagedBy = "terraform"
      Challenge = "30-day-terraform"
      Owner     = "Wadonderah"
    }
  }
}

# ── Default provider (needed for Route53 — global service) ────────────────────
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "multi-region-ha"
      ManagedBy = "terraform"
      Challenge = "30-day-terraform"
      Owner     = "Wadonderah"
    }
  }
}

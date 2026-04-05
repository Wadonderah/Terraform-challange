# -----------------------------------------------------------------------------
# live/production/services/webserver-cluster/main.tf
#
# Production environment — intentionally pinned to v0.0.1.
#
# WHY: v0.0.2 is currently being validated in dev. Production stays on the
# last known-good version until:
#   1. Dev has run v0.0.2 cleanly for a full cycle
#   2. A plan review confirms no destructive changes
#   3. The team promotes the version via a PR updating this source ref
#
# This is the core safety contract of module versioning: dev tests forward,
# production follows deliberately. Never let production float to "latest".
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"

  # REQUIRED for production: remote state with locking
  backend "s3" {
    bucket         = "wadondera-terraform-state-556684850027"
    key            = "production/services/webserver-cluster/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Project     = "webserver-cluster"
    }
  }
}

# Production stays on v0.0.1 — the stable, validated version

module "webserver_cluster" {
  source = "github.com/Wadonderah/terraform-aws-webserver-cluster?ref=v0.0.1"

  cluster_name             = "webservers-production"
  instance_type            = "t3.medium" # appropriately sized for production load
  min_size                 = 4
  max_size                 = 10
  desired_capacity         = 6
  enable_cloudwatch_alarms = true

  extra_tags = {
    Environment = "production"
    CostCenter  = "engineering-prod"
    Criticality = "high"
  }
}

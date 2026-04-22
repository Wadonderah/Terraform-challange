# =============================================================================
# environments/dev/main.tf
# Day 28: Terraform Associate Exam Prep
#
# This file demonstrates calling the root module from an environment directory.
# It passes environment-specific variables through to the root module.
# =============================================================================

module "day28" {
  source = "../../"

  environment    = "dev"
  aws_region     = "us-east-1"
  instance_type  = "t3.micro"
  instance_count = 1
}
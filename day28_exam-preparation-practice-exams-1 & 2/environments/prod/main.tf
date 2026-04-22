# =============================================================================
# environments/prod/main.tf
# Day 28: Terraform Associate Exam Prep
# =============================================================================

module "day28" {
  source = "../../"

  environment    = "prod"
  aws_region     = "us-east-1"
  instance_type  = "t3.small"
  instance_count = 2
}
# =============================================================================
# environments/prod/terraform.tfvars
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Workspaces vs separate directories
# This project uses separate tfvars files per environment.
# An alternative is terraform workspaces:
#   terraform workspace new prod
#   terraform workspace select prod
#   terraform apply  # uses workspace name in resource naming
#
# Separate directories (this approach) is generally preferred for prod
# because it allows different backends and prevents accidental cross-env apply.
# =============================================================================

environment    = "prod"
aws_region     = "us-east-1"
project        = "day28-terraform-challenge"
instance_type  = "t3.small"
instance_count = 2
vpc_cidr       = "10.1.0.0/16"

public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]

tags = {
  Team       = "platform"
  CostCentre = "engineering"
  Day        = "28"
  Critical   = "true"
}
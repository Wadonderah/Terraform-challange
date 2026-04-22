# =============================================================================
# environments/dev/terraform.tfvars
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: terraform.tfvars and variable precedence
# Terraform loads variable values in this order (later = higher precedence):
#   1. Default values in variables.tf
#   2. terraform.tfvars in the working directory
#   3. *.auto.tfvars files (alphabetical order)
#   4. -var and -var-file flags on the command line
#   5. TF_VAR_* environment variables
#
# Usage:
#   terraform plan -var-file="environments/dev/terraform.tfvars"
#   terraform apply -var-file="environments/dev/terraform.tfvars"
# =============================================================================

environment    = "dev"
aws_region     = "us-east-1"
project        = "day28-terraform-challenge"
instance_type  = "t3.micro"
instance_count = 1
vpc_cidr       = "10.0.0.0/16"

public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# NOTE: Do NOT store real secrets in tfvars files committed to version control.
# This is a demo value only. Use TF_VAR_db_password env var in real workflows.
# db_password is intentionally omitted here - set via environment variable:
#   export TF_VAR_db_password="your-secure-password"

tags = {
  Team      = "platform"
  CostCentre = "engineering"
  Day        = "28"
}
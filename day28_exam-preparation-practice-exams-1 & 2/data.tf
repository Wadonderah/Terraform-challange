# =============================================================================
# data.tf
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Data sources
# Data sources read existing infrastructure. They do NOT create resources.
# terraform refresh reconciles state with real-world values from data sources.
# =============================================================================

# Current AWS account identity
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Available AZs in the current region
# Used in locals.tf to distribute subnets across AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Latest Amazon Linux 2 AMI
# EXAM CONCEPT: Data sources are re-evaluated on every plan.
# If this AMI changes between plans, Terraform will detect the drift.
# This is how terraform refresh updates state to match real-world values.
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

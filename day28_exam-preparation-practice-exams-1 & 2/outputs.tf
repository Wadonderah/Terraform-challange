# =============================================================================
# outputs.tf - Root Module Outputs
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Output values and the sensitive argument
#
# WRONG ANSWER TRAP: sensitive = true encrypts the value in the state file.
# CORRECT:
#   sensitive = true does TWO things:
#     1. Suppresses the value in terraform apply / terraform output CLI output
#     2. Forces child modules to also mark the value sensitive if they use it
#   It does NOT:
#     - Encrypt the value in terraform.tfstate
#     - Prevent access via: terraform output -json  (bypasses suppression)
#     - Prevent access via: cat terraform.tfstate   (plaintext in state)
#
# To verify this yourself after apply:
#   terraform output db_password          # shows (sensitive value)
#   terraform output -json db_password    # shows the actual value
#   cat terraform.tfstate | python3 -m json.tool | grep -A1 db_password
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC created by the vpc module."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

# -----------------------------------------------------------------------------
# Compute Outputs
# -----------------------------------------------------------------------------
output "instance_ids" {
  description = "IDs of the EC2 instances created."
  value       = module.compute.instance_ids
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances."
  value       = module.compute.public_ips
}

# -----------------------------------------------------------------------------
# Sensitive Output Demo
# EXAM NOTE: This value is suppressed in CLI output.
# It is NOT encrypted in terraform.tfstate - still plaintext.
# -----------------------------------------------------------------------------
output "db_password" {
  description = <<-EOT
    Database password (sensitive).
    EXAM REMINDER: This is suppressed in CLI output only.
    Run: terraform output -json db_password
    to see that sensitive=true does not prevent access to the value.
    The value is also stored in plaintext in terraform.tfstate.
  EOT
  value     = var.db_password
  sensitive = true
}

# -----------------------------------------------------------------------------
# State Demo Outputs
# -----------------------------------------------------------------------------
output "state_demo_bucket_name" {
  description = "Name of the S3 bucket created by the state_demo module. Use this to practice terraform import."
  value       = module.state_demo.bucket_name
}

output "state_demo_bucket_arn" {
  description = "ARN of the S3 bucket created by the state_demo module."
  value       = module.state_demo.bucket_arn
}

# -----------------------------------------------------------------------------
# Metadata Outputs
# -----------------------------------------------------------------------------
output "account_id" {
  description = "AWS account ID where resources are deployed."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region where resources are deployed."
  value       = data.aws_region.current.name
}

output "environment" {
  description = "Deployment environment."
  value       = var.environment
}

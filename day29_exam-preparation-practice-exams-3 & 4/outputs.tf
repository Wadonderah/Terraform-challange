# =============================================================================
# outputs.tf - Root Module
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
# =============================================================================

output "random_demo_id" {
  description = "Random ID from random_demo module. Use for state practice."
  value       = module.random_demo.id
}

output "workspace_info" {
  description = "Current workspace name and workspace-aware resource info."
  value       = module.workspace_demo.info
}

output "account_id" {
  description = "AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region."
  value       = data.aws_region.current.name
}

output "db_password_demo" {
  description = "Sensitive output demo. CLI suppresses this; state does not."
  value       = var.db_password
  sensitive   = true
}
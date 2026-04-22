# =============================================================================
# modules/compute/outputs.tf
# Day 28: Terraform Associate Exam Prep
#
# EXAM CONCEPT: Module outputs
# Outputs expose values from child modules to the root module.
# The root module's outputs.tf then re-exposes selected values to the operator.
# =============================================================================

output "instance_ids" {
  description = "IDs of the EC2 instances. Use these to practice: terraform state show"
  value       = aws_instance.this[*].id
}

output "public_ips" {
  description = "Public IPs of the EC2 instances."
  value       = aws_instance.this[*].public_ip
}

output "security_group_id" {
  description = "ID of the security group."
  value       = aws_security_group.web.id
}
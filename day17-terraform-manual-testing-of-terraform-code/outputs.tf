##############################################################
# outputs.tf — Root Module
# Day 17: Manual Testing of Terraform Code
##############################################################

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — use this to curl and verify"
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.compute.alb_arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.asg_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (ALB lives here)"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (EC2 instances live here)"
  value       = module.networking.private_subnet_ids
}

output "alb_sg_id" {
  description = "Security group ID attached to the ALB"
  value       = module.security.alb_sg_id
}

output "instance_sg_id" {
  description = "Security group ID attached to EC2 instances"
  value       = module.security.instance_sg_id
}

output "test_curl_command" {
  description = "Ready-to-run curl command for functional verification"
  value       = "curl -s http://${module.compute.alb_dns_name}"
}

output "environment" {
  description = "Active deployment environment"
  value       = var.environment
}

output "target_group_arn" {
  description = "ARN of the target group — use in: aws elbv2 describe-target-health"
  value       = module.compute.target_group_arn
}

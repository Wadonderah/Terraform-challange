# =============================================================================
# ENVIRONMENT: production — outputs.tf
# =============================================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer. Point your DNS CNAME here."
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = module.compute.alb_arn
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (ALB lives here)."
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (EC2 instances live here)."
  value       = module.networking.private_subnet_ids
}

output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = module.compute.asg_name
}

output "state_bucket_id" {
  description = "Name of the Terraform remote state S3 bucket."
  value       = module.storage.state_bucket_id
}

output "dynamodb_table_name" {
  description = "Name of the Terraform state lock DynamoDB table."
  value       = module.storage.dynamodb_table_name
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS alerts topic."
  value       = module.monitoring.sns_topic_arn
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard for this cluster."
  value       = module.monitoring.dashboard_url
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption."
  value       = module.security.kms_key_arn
  sensitive   = true
}

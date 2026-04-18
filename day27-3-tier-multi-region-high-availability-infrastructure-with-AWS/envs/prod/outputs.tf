# =============================================================================
# Production Environment Outputs
# After `terraform apply`, run `terraform output` to retrieve these values.
# =============================================================================

# ── Application Access ────────────────────────────────────────────────────────
# Route53 module is commented out - access via ALB URLs directly
# output "application_url" {
#   value       = module.route53.application_url
#   description = "Primary URL — served via Route53 failover DNS"
# }

output "primary_alb_url" {
  value       = "http://${module.alb_primary.alb_dns_name}"
  description = "Direct URL to the primary region ALB - USE THIS TO ACCESS YOUR APP"
}

output "secondary_alb_url" {
  value       = "http://${module.alb_secondary.alb_dns_name}"
  description = "Direct URL to the secondary region ALB - USE THIS TO ACCESS YOUR APP"
}

# ── VPC ───────────────────────────────────────────────────────────────────────
output "primary_vpc_id" {
  value       = module.vpc_primary.vpc_id
  description = "VPC ID in us-east-1"
}

output "secondary_vpc_id" {
  value       = module.vpc_secondary.vpc_id
  description = "VPC ID in us-west-2"
}

# ── ALB ───────────────────────────────────────────────────────────────────────
output "primary_alb_dns_name" {
  value       = module.alb_primary.alb_dns_name
  description = "DNS name of the primary region Application Load Balancer"
}

output "secondary_alb_dns_name" {
  value       = module.alb_secondary.alb_dns_name
  description = "DNS name of the secondary region Application Load Balancer"
}

# ── ASG ───────────────────────────────────────────────────────────────────────
output "primary_asg_name" {
  value       = module.asg_primary.asg_name
  description = "Auto Scaling Group name in us-east-1"
}

output "secondary_asg_name" {
  value       = module.asg_secondary.asg_name
  description = "Auto Scaling Group name in us-west-2"
}

# ── RDS ───────────────────────────────────────────────────────────────────────
output "primary_db_endpoint" {
  value       = module.rds_primary.db_endpoint
  description = "Primary RDS endpoint (Multi-AZ, us-east-1)"
  sensitive   = true
}

output "replica_db_endpoint" {
  value       = module.rds_replica.db_endpoint
  description = "Read replica RDS endpoint (us-west-2)"
  sensitive   = true
}

output "primary_db_arn" {
  value       = module.rds_primary.db_instance_arn
  description = "ARN of the primary RDS instance — used as replicate_source_db"
}

# ── Route53 ───────────────────────────────────────────────────────────────────
# Route53 module is commented out - uncomment when you have a domain
# output "primary_health_check_id" {
#   value       = module.route53.primary_health_check_id
#   description = "Route53 health check ID for the primary region"
# }
#
# output "secondary_health_check_id" {
#   value       = module.route53.secondary_health_check_id
#   description = "Route53 health check ID for the secondary region"
# }

# ── S3 Cross-Region Replication ───────────────────────────────────────────────
output "primary_assets_bucket" {
  value       = aws_s3_bucket.primary_assets.bucket
  description = "S3 bucket name for static assets in us-east-1"
}

output "secondary_assets_bucket" {
  value       = aws_s3_bucket.secondary_assets.bucket
  description = "S3 bucket name for static assets in us-west-2 (replication destination)"
}

output "replication_role_arn" {
  value       = aws_iam_role.replication.arn
  description = "IAM role ARN used by S3 cross-region replication"
}

# modules/services/hello-wadondera-app/outputs.tf

output "alb_dns_name" {
  description = "DNS name of the ALB — paste this in your browser"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "asg_name" {
  value = module.asg.asg_name
}

output "db_endpoint" {
  description = "RDS endpoint for app connection string"
  value       = module.mysql.db_endpoint
}

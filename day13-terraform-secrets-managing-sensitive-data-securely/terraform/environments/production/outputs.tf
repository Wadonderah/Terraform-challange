# =============================================================================
# outputs.tf
# =============================================================================

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = length(aws_db_instance.primary) > 0 ? aws_db_instance.primary[0].endpoint : "RDS not deployed — set vpc_id and private_subnet_ids in terraform.tfvars"
  sensitive   = false
}

output "rds_arn" {
  description = "RDS instance ARN"
  value       = length(aws_db_instance.primary) > 0 ? aws_db_instance.primary[0].arn : ""
  sensitive   = false
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret — reference this in your application config"
  value       = data.aws_secretsmanager_secret.db_credentials.arn
  sensitive   = false
}

output "db_username" {
  description = "Database master username (sensitive)"
  value       = local.db_credentials["username"]
  sensitive   = true
}

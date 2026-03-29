# =============================================================================
# modules/rds/outputs.tf
# =============================================================================

output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.this.endpoint
  sensitive   = false
}

output "arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
  sensitive   = false
}

output "id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
  sensitive   = false
}

output "username" {
  description = "Database master username"
  value       = aws_db_instance.this.username
  sensitive   = true
}

# modules/data-stores/mysql/outputs.tf

output "db_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "Port the RDS instance listens on"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "rds_security_group_id" {
  description = "Security group ID attached to the RDS instance"
  value       = aws_security_group.rds.id
}

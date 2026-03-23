output "db_instance_endpoint" {
  description = "Connection endpoint for the RDS instance (host:port)"
  value       = aws_db_instance.default.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.default.address
}

output "db_instance_port" {
  description = "Port the RDS instance is listening on"
  value       = aws_db_instance.default.port
}

output "db_security_group_id" {
  description = "ID of the RDS security group. Expose so callers can allow ingress from specific sources."
  value       = aws_security_group.rds.id
}

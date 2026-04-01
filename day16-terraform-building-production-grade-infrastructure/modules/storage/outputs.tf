output "state_bucket_id" {
  description = "The ID (name) of the Terraform state S3 bucket."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.state.arn
}

output "config_bucket_id" {
  description = "The ID (name) of the application config S3 bucket."
  value       = aws_s3_bucket.config.id
}

output "config_bucket_arn" {
  description = "ARN of the application config S3 bucket."
  value       = aws_s3_bucket.config.arn
}

output "alb_access_logs_bucket_id" {
  description = "The ID (name) of the S3 bucket for ALB access logs."
  value       = aws_s3_bucket.alb_access_logs.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB state lock table."
  value       = aws_dynamodb_table.state_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB state lock table."
  value       = aws_dynamodb_table.state_lock.arn
}

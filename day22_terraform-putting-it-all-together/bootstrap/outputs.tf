# bootstrap/outputs.tf

output "state_bucket_name" {
  description = "S3 bucket name — paste into all backend blocks"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table name — paste into all backend blocks"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN — paste into the GitHub Actions workflow role-to-assume"
  value       = aws_iam_role.github_actions_terraform.arn
}

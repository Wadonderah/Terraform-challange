# modules/multi-region-app/outputs.tf

output "primary_bucket_id" {
  description = "Name of the primary S3 bucket (us-east-1)."
  value       = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket."
  value       = aws_s3_bucket.primary.arn
}

output "replica_bucket_id" {
  description = "Name of the replica S3 bucket (us-west-2)."
  value       = aws_s3_bucket.replica.id
}

output "replica_bucket_arn" {
  description = "ARN of the replica S3 bucket."
  value       = aws_s3_bucket.replica.arn
}

output "replication_role_arn" {
  description = "ARN of the IAM role used for S3 cross-region replication."
  value       = aws_iam_role.replication.arn
}


output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail S3 bucket — use this in your CloudTrail resource"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

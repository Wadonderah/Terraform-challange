output "example_bucket_arn" {
  description = "ARN of the example bucket"
  value       = aws_s3_bucket.example.arn
}

output "example_bucket_name" {
  description = "Name of the example bucket"
  value       = aws_s3_bucket.example.bucket
}

output "example_bucket_region" {
  description = "Region where the bucket was created"
  value       = aws_s3_bucket.example.region
}

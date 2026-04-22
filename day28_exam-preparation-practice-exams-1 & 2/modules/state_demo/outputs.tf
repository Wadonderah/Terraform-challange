output "bucket_name" { description = "S3 bucket name for state import practice." ; value = aws_s3_bucket.demo.bucket }
output "bucket_arn"  { description = "S3 bucket ARN." ; value = aws_s3_bucket.demo.arn }
output "table_name"  { description = "DynamoDB table name." ; value = aws_dynamodb_table.locks.name }
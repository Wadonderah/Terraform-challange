# envs/prod/terraform.tfvars
aws_region          = "us-east-1"
bucket_name         = "wadondera-prod"
project_name        = "wadondera"
website_title       = "Welcome Back Wadondera"
website_description = "Your infrastructure is live · Production environment"

# Uncomment and fill in when you have a custom domain:
# domain_name         = "yourdomain.com"
# route53_zone_id     = "Z1234567890ABCDEF"
# acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-def-123"
# log_bucket_name     = "my-cloudfront-logs-bucket"

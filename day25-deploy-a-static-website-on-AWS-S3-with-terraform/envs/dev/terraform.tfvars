# envs/dev/terraform.tfvars
# Replace bucket_name with a globally unique value before running.
# Tip: append your AWS account ID: "my-website-dev-123456789012"

aws_region          = "us-east-1"
bucket_name         = "wadondera-static-website-dev-123"
environment         = "dev"
project_name        = "wadondera"
website_title       = "Welcome Back Wadondera"
website_description = "Your infrastructure is live · Deployed with Terraform on AWS"
index_document      = "index.html"
error_document      = "error.html"

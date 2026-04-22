# environments/prod/terraform.tfvars
# Day 29 | 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM: Variable precedence (lowest to highest):
#   1. Default values in variables.tf
#   2. terraform.tfvars in working directory
#   3. *.auto.tfvars (alphabetical)
#   4. -var-file flag
#   5. -var flag
#   6. TF_VAR_* environment variables
#
# Usage: terraform plan -var-file="environments/prod/terraform.tfvars"

environment   = "prod"
aws_region    = "us-east-1"
project       = "day29-terraform-challenge"
instance_type = "t3.medium"
vpc_cidr      = "10.2.0.0/16"

tags = {
  Team       = "platform"
  CostCentre = "engineering"
  Day        = "29"
}
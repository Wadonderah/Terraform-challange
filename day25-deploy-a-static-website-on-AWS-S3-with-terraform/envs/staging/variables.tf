# envs/staging/variables.tf

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type = string
}

variable "project_name" {
  type    = string
  default = "static-website"
}

variable "website_title" {
  type    = string
  default = "Deployed with Terraform"
}

variable "website_description" {
  type    = string
  default = "Staging environment"
}

variable "domain_name" {
  type    = string
  default = null
}

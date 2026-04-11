# envs/prod/variables.tf

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
  default = "Production"
}

variable "domain_name" {
  type    = string
  default = null
}

variable "route53_zone_id" {
  type    = string
  default = null
}

variable "acm_certificate_arn" {
  type    = string
  default = null
}

variable "log_bucket_name" {
  type    = string
  default = null
}

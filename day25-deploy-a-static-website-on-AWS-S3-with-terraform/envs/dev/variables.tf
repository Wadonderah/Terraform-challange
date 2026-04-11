# envs/dev/variables.tf

variable "aws_region" {
  description = "AWS region for the S3 bucket and supporting resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "static-website"
}

variable "website_title" {
  description = "Title shown on the generated landing page"
  type        = string
  default     = "Deployed with Terraform"
}

variable "website_description" {
  description = "Subtitle shown on the generated landing page"
  type        = string
  default     = "Day 25 — 30-Day Terraform Challenge"
}

variable "index_document" {
  description = "Index document filename"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document filename"
  type        = string
  default     = "error.html"
}

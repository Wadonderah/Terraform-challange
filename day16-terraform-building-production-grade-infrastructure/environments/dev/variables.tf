variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "cluster_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "team_name" {
  type = string
}

variable "cost_center" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "server_port" {
  type    = number
  default = 80
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "state_bucket_name" {
  type = string
}

variable "config_bucket_name" {
  type = string
}

variable "dynamodb_table_name" {
  type    = string
  default = "terraform-state-lock"
}

variable "alert_email_addresses" {
  type    = list(string)
  default = []
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "cpu_high_threshold" {
  type    = number
  default = 80
}

variable "cpu_low_threshold" {
  type    = number
  default = 20
}

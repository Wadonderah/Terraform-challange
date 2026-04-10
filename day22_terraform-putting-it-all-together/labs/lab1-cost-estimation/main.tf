# labs/lab1-cost-estimation/main.tf
# Lab 1: Cost Estimation
#
# This lab demonstrates Terraform Cloud cost estimation. Deploy this stack,
# then check the Terraform Cloud run page — you will see a cost estimate
# showing the monthly price before you approve the apply.
#
# Objectives:
#   1. See cost estimation in a Terraform Cloud run
#   2. Observe how changing instance_type changes the estimated cost
#   3. Trigger the cost-check Sentinel policy by setting a large instance
#
# Usage:
#   cd labs/lab1-cost-estimation
#   terraform init
#   terraform plan     # view cost estimate in TFC run page
#   terraform apply
#   terraform destroy  # always clean up lab resources

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Connect this to your Terraform Cloud workspace to see cost estimation
  # cloud {
  #   organization = "YOUR-TFC-ORG"
  #   workspaces {
  #     name = "lab1-cost-estimation"
  #   }
  # }
}

provider "aws" {
  region = var.aws_region
}

# ── Exercise 1: single EC2 instance — check the monthly cost estimate ──────
resource "aws_instance" "lab_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type   # Change this to see cost change

  tags = {
    Name      = "lab1-cost-estimation"
    ManagedBy = "terraform"
    Lab       = "cost-estimation"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ── Exercise 2: RDS instance — observe the larger cost contribution ────────
resource "aws_db_instance" "lab_db" {
  identifier          = "lab1-cost-db"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = var.db_instance_class
  allocated_storage   = 20
  storage_encrypted   = true
  username            = "labadmin"
  password            = var.db_password
  skip_final_snapshot = true

  tags = {
    Name      = "lab1-cost-db"
    ManagedBy = "terraform"
    Lab       = "cost-estimation"
  }
}

# ── Variables ──────────────────────────────────────────────────────────────
variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "instance_type" {
  description = "Try: t3.micro ($8/mo), t3.medium ($30/mo), m5.xlarge ($140/mo)"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "Try: db.t3.micro ($15/mo), db.t3.medium ($60/mo)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_password" {
  type      = string
  sensitive = true
}

# ── Outputs ────────────────────────────────────────────────────────────────
output "instance_id" {
  value = aws_instance.lab_server.id
}

output "instance_type_selected" {
  value       = var.instance_type
  description = "Check the Terraform Cloud run for the monthly cost estimate"
}

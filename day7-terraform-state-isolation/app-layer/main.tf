
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "wadondera-terraform-state-556684850027"
    key            = "environments/dev/app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# Remote State Data Source
# Reads outputs from the dev networking layer

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "wadondera-terraform-state-556684850027"
    key    = "environments/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# App server placed into the subnet created by the networking layer

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  # Reference output from remote state — no hard-coded IDs
  subnet_id = data.terraform_remote_state.network.outputs.subnet_id

  tags = {
    Name        = "app-server-dev"
    Environment = "dev"
    VPC         = data.terraform_remote_state.network.outputs.vpc_id
    ManagedBy   = "Terraform"
  }
}

output "app_instance_id" {
  value = aws_instance.app.id
}

output "source_vpc_id" {
  description = "VPC ID pulled from networking layer remote state"
  value       = data.terraform_remote_state.network.outputs.vpc_id
}

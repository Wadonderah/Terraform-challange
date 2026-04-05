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
    key            = "dev/services/webserver-cluster/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Team        = "platform"
    }
  }
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name       = "webservers-dev"
  instance_type      = "t3.micro" # Free tier eligible
  min_size           = 2          # 2 instances = HA across AZs
  max_size           = 4          # Cap spend in dev
  enable_autoscaling = false      # Stable environment for testing

  custom_tags = {
    CostCenter = "engineering-dev"
  }
}

output "alb_dns_name" {
  description = "Hit this URL to verify the dev cluster is serving traffic"
  value       = module.webserver_cluster.alb_dns_name
}

output "asg_name" {
  value = module.webserver_cluster.asg_name
}

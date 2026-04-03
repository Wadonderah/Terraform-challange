##############################################################
# main.tf — Root module (Day 18)
# Calls the webserver-cluster module for dev and prod.
# The module itself is what gets tested — this root module
# is used for manual deployment when needed.
##############################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = "day18-automated-testing"
      Environment = var.environment
    }
  }
}

module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"

  cluster_name     = var.cluster_name
  instance_type    = var.instance_type
  min_size         = var.min_size
  max_size         = var.max_size
  environment      = var.environment
  server_port      = var.server_port
  alb_port         = var.alb_port
  hello_world_text = var.hello_world_text
  aws_region       = var.aws_region
  ami_id           = var.ami_id
}

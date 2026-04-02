##############################################################
# main.tf — Root Module
# Day 17: Manual Testing of Terraform Code
# Orchestrates networking, security, and compute modules
##############################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure to use remote state (recommended for production)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "day17/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        ManagedBy   = "terraform"
        Project     = var.project_name
        Environment = var.environment
        Day         = "17"
      },
      var.tags
    )
  }
}

##############################################################
# DATA SOURCES
##############################################################

data "aws_availability_zones" "available" {
  state = "available"
}

##############################################################
# MODULE: NETWORKING
# Creates VPC, subnets, IGW, NAT Gateway, and route tables
##############################################################

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = data.aws_availability_zones.available.names
}

##############################################################
# MODULE: SECURITY
# Creates security groups for ALB and EC2 instances
##############################################################

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  server_port  = var.server_port
  alb_port     = var.alb_port
}

##############################################################
# MODULE: COMPUTE
# Creates ALB, Target Group, ASG, and Launch Template
##############################################################

module "compute" {
  source = "./modules/compute"

  project_name         = var.project_name
  environment          = var.environment
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  server_port          = var.server_port
  alb_port             = var.alb_port
  health_check_path    = var.health_check_path
  hello_world_version  = var.hello_world_version
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  alb_sg_id            = module.security.alb_sg_id
  instance_sg_id       = module.security.instance_sg_id
}

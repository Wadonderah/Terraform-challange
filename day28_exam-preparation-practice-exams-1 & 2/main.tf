# =============================================================================
# main.tf - Root Module
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Root module calls child modules.
# This file demonstrates:
#   - Local module calls (no version argument supported)
#   - Registry module calls (version argument supported)
#   - Module outputs consumed by other modules
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# =============================================================================
# MODULE: VPC
# Source: local path - version argument NOT supported on local modules
#
# WRONG ANSWER TRAP: "All module sources support the version argument."
# CORRECT:          Only registry sources support version.
#                   Local paths: no version argument (use path directly)
#                   Git sources: no version argument (use ?ref= in URL)
# =============================================================================
module "vpc" {
  source = "./modules/vpc"

  # Local modules do NOT accept a version argument.
  # Uncommenting the line below would cause an error:
  # version = "1.0.0"  # ERROR: version not supported for local modules

  name                 = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.availability_zones
  tags                 = local.common_tags
}

# =============================================================================
# MODULE: COMPUTE
# Source: local path - demonstrates module input/output chaining
# The compute module consumes VPC module outputs.
# =============================================================================
module "compute" {
  source = "./modules/compute"

  name           = local.name_prefix
  instance_type  = var.instance_type
  instance_count = var.instance_count
  ami_id         = var.ami_id
  subnet_id      = module.vpc.public_subnet_ids[0]
  vpc_id         = module.vpc.vpc_id
  tags           = local.common_tags
}

# =============================================================================
# MODULE: STATE DEMO
# Demonstrates state management concepts tested in the exam.
# Run these commands after terraform apply:
#
#   terraform state list
#   terraform state show module.state_demo.aws_s3_bucket.demo
#   terraform state mv module.state_demo.aws_s3_bucket.demo module.state_demo.aws_s3_bucket.renamed
#   terraform state rm module.state_demo.aws_s3_bucket.renamed
#   # Note: bucket still exists in AWS after state rm
#   terraform import module.state_demo.aws_s3_bucket.demo <bucket-name>
# =============================================================================
module "state_demo" {
  source = "./modules/state_demo"

  name        = local.name_prefix
  environment = var.environment
  tags        = local.common_tags
}

# =============================================================================
# REGISTRY MODULE EXAMPLE
# This is commented out to avoid unexpected AWS charges.
# Uncomment to test registry module versioning.
#
# EXAM CONCEPT: Registry modules support the version argument.
# The ~> operator (pessimistic constraint) allows only patch-level upgrades:
#   version = "~> 5.1" allows 5.1.x but NOT 5.2.0
#   version = "~> 5.0" allows 5.x.x but NOT 6.0.0
# =============================================================================
# module "vpc_registry" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.1"   # Registry modules SUPPORT version argument
#
#   name = "${local.name_prefix}-registry-vpc"
#   cidr = "10.1.0.0/16"
#
#   azs             = local.availability_zones
#   private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
#   public_subnets  = ["10.1.10.0/24", "10.1.11.0/24"]
# }

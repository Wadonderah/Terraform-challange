# =============================================================================
# ENVIRONMENT: production
# Description: Composes all modules into production-grade infrastructure.
# All resources inherit common_tags via the locals block below.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state backend — bootstrapped by the storage module
  # Backend configured via -backend-config flags or backend.hcl file.
  # Run: terraform init -backend-config=backend.hcl
  # See scripts/bootstrap-remote-state.sh to create the bucket first.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# ---------------------------------------------------------------------------
# Common Tags — applied to EVERY resource in this environment
# ---------------------------------------------------------------------------

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Owner       = var.team_name
    CostCenter  = var.cost_center
  }
}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# Latest Amazon Linux 2023 AMI

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# Module: Security (deployed first — others depend on it)
# ---------------------------------------------------------------------------

module "security" {
  source = "../../modules/security"

  cluster_name       = var.cluster_name
  vpc_id             = module.networking.vpc_id
  server_port        = var.server_port
  config_bucket_name = var.config_bucket_name
  common_tags        = local.common_tags
}

# ---------------------------------------------------------------------------
# Module: Storage
# ---------------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage"

  cluster_name        = var.cluster_name
  state_bucket_name   = var.state_bucket_name
  config_bucket_name  = var.config_bucket_name
  dynamodb_table_name = var.dynamodb_table_name
  kms_key_arn         = module.security.kms_key_arn
  common_tags         = local.common_tags
}

# ---------------------------------------------------------------------------
# Module: Networking
# ---------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  common_tags        = local.common_tags
}

# ---------------------------------------------------------------------------
# Module: Compute
# ---------------------------------------------------------------------------
module "compute" {
  source = "../../modules/compute"

  cluster_name          = var.cluster_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  web_security_group_id = module.security.web_security_group_id
  instance_profile_name = module.security.ec2_instance_profile_name
  kms_key_arn           = module.security.kms_key_arn
  ami_id                = data.aws_ami.amazon_linux_2023.id
  instance_type         = var.instance_type
  server_port           = var.server_port
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  access_logs_bucket    = module.storage.alb_access_logs_bucket_id
  acm_certificate_arn   = var.acm_certificate_arn
  common_tags           = local.common_tags
}

# ---------------------------------------------------------------------------
# Module: Monitoring
# ---------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  cluster_name            = var.cluster_name
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = split("loadbalancer/", module.compute.alb_arn)[1]
  target_group_arn_suffix = split(":targetgroup/", module.compute.target_group_arn)[1]
  scale_out_policy_arn    = module.compute.scale_out_policy_arn
  scale_in_policy_arn     = module.compute.scale_in_policy_arn
  kms_key_id              = module.security.kms_key_id
  alert_email_addresses   = var.alert_email_addresses
  log_retention_days      = var.log_retention_days
  cpu_high_threshold      = var.cpu_high_threshold
  cpu_low_threshold       = var.cpu_low_threshold
  common_tags             = local.common_tags
}

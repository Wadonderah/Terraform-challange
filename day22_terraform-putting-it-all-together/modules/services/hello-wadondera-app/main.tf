# modules/services/hello-wadondera-app/main.tf
# Top-level composition module — wires VPC + ALB + ASG + MySQL together

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "vpc" {
  source = "../../networking/vpc"

  name        = "${var.environment}-${var.app_name}"
  environment = var.environment

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "alb" {
  source = "../../load-balancing/alb"

  alb_name          = "${var.environment}-${var.app_name}-alb"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  target_port       = var.server_port
  health_check_path = "/health"
}

module "asg" {
  source = "../../compute/asg-rolling-deploy"

  cluster_name          = "${var.environment}-${var.app_name}"
  environment           = var.environment
  instance_type         = var.instance_type
  min_size              = var.min_size
  max_size              = var.max_size
  enable_autoscaling    = var.enable_autoscaling
  server_port           = var.server_port
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  target_group_arn      = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id
}

module "mysql" {
  source = "../../data-stores/mysql"

  db_name     = "${var.environment}-${var.app_name}-db"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.asg.instance_security_group_id]

  db_username         = var.db_username
  db_password         = var.db_password
  db_instance_class   = var.db_instance_class
  multi_az            = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment == "prod" ? false : true
  deletion_protection = var.environment == "prod" ? true : false
}

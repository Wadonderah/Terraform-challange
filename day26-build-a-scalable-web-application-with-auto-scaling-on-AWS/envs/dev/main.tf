# ─────────────────────────────────────────────────────────────────────────────
# Day 26 — Scalable Web Application: Dev Environment Root
#
# Data flow summary:
#   module.ec2  →  launch_template_id / launch_template_version  →  module.asg
#   module.alb  →  target_group_arn                              →  module.asg
#   module.asg  attaches instances to the ALB target group via target_group_arns
# ─────────────────────────────────────────────────────────────────────────────

# ─── Module 1: ALB (must be created first to provide security group ID) ─────
module "alb" {
  source      = "../../modules/alb"
  name        = var.app_name
  vpc_id      = var.vpc_id
  subnet_ids  = var.public_subnet_ids
  environment = var.environment

  tags = {
    Owner = "terraform-challenge"
    Day   = "26"
  }
}

# ─── Module 2: EC2 (depends on ALB security group) ──────────────────────────
module "ec2" {
  source                = "../../modules/ec2"
  ami_id                = var.ami_id
  instance_type         = var.instance_type
  key_name              = var.key_name
  vpc_id                = var.vpc_id
  alb_security_group_id = module.alb.alb_security_group_id
  environment           = var.environment

  tags = {
    Owner = "terraform-challenge"
    Day   = "26"
  }
}

module "asg" {
  source = "../../modules/asg"

  # Wired directly from module.ec2 outputs — no hardcoding
  launch_template_id      = module.ec2.launch_template_id
  launch_template_version = module.ec2.launch_template_version

  # Private subnets keep instances off the public internet
  subnet_ids = var.private_subnet_ids

  # Wired directly from module.alb output — closes the ALB ↔ ASG loop
  target_group_arns = [module.alb.target_group_arn]

  min_size                = var.min_size
  max_size                = var.max_size
  desired_capacity        = var.desired_capacity
  cpu_scale_out_threshold = var.cpu_scale_out_threshold
  cpu_scale_in_threshold  = var.cpu_scale_in_threshold
  environment             = var.environment

  tags = {
    Owner = "terraform-challenge"
    Day   = "26"
  }
}

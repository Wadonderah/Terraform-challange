##############################################################
# modules/compute/main.tf
# Day 17: Manual Testing — Chapter 9
#
# Creates: Launch Template, Auto Scaling Group,
#          Application Load Balancer, Target Group, Listener
#
# NOTE: No automated scaling policies here.
# Scaling alarms belong in Chapter 10 (automated testing).
# The ASG self-healing (replacing unhealthy instances) is
# built-in AWS behaviour — you verify it MANUALLY in Step 14
# of the manual testing checklist.
##############################################################

locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    server_port         = var.server_port
    hello_world_version = var.hello_world_version
    environment         = var.environment
  }))
}

##############################################################
# LAUNCH TEMPLATE
# Defines the configuration for every EC2 instance the ASG
# launches. IMDSv2 required — prevents SSRF attacks against
# the instance metadata endpoint.
##############################################################

resource "aws_launch_template" "this" {
  name_prefix            = "${var.project_name}-${var.environment}-lt-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.instance_sg_id]
  user_data              = local.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-instance"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name      = "${var.project_name}-${var.environment}-volume"
      ManagedBy = "terraform"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-launch-template"
  }
}

##############################################################
# APPLICATION LOAD BALANCER
# Internet-facing. Lives in public subnets.
# Distributes HTTP :80 traffic across healthy EC2 instances.
##############################################################

resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

##############################################################
# TARGET GROUP
# The ALB forwards to this group. Health checks run here.
# Manual test Step 9: verify all instances show "healthy".
##############################################################

resource "aws_lb_target_group" "this" {
  name                 = "${var.project_name}-${var.environment}-tg"
  port                 = var.server_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

##############################################################
# ALB LISTENER
# HTTP :80 — forwards all requests to the target group.
# Manual test Step 8: verify this listener exists in Console.
##############################################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-http-listener"
  }
}

##############################################################
# AUTO SCALING GROUP
# Spreads instances across private subnets (one per AZ).
# Self-healing is AWS built-in behaviour — if the health
# check type is ELB, the ASG automatically replaces any
# instance the ALB marks unhealthy.
# Manual test Step 14: terminate an instance manually and
# watch the ASG replace it — no Terraform config needed.
##############################################################

resource "aws_autoscaling_group" "this" {
  name = "${var.project_name}-${var.environment}-asg"

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.this.arn]

  # ELB health check: the ASG asks the ALB whether each instance
  # is healthy, rather than just checking if the EC2 is running.
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

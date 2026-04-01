# =============================================================================
# MODULE: compute
# Description: ALB, Target Group, Auto Scaling Group, Launch Template
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Module = "compute"
  })

  # User data script — installs a simple web server
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    cluster_name = var.cluster_name
    environment  = var.environment
    server_port  = var.server_port
  }))
}

# ---------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------
resource "aws_lb" "main" {
  name_prefix        = substr("${var.cluster_name}-", 0, 6)
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "production" ? true : false
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = "alb/${var.cluster_name}"
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alb"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Redirect HTTP → HTTPS in production; allow HTTP in dev/staging
  dynamic "default_action" {
    for_each = var.environment == "production" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.environment != "production" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main.arn
    }
  }

  tags = local.common_tags
}

# HTTPS listener — only created in production when an ACM certificate is provided
resource "aws_lb_listener" "https" {
  count = var.environment == "production" && var.acm_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Target Group with health checks
# ---------------------------------------------------------------------------
resource "aws_lb_target_group" "main" {
  # Use name_prefix so Terraform can create a new TG before destroying the old
  name_prefix = substr(var.cluster_name, 0, 6)
  port        = var.server_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }

  # CRITICAL: create_before_destroy prevents downtime when TG must be replaced
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-tg"
  })
}

# ---------------------------------------------------------------------------
# Launch Template
# ---------------------------------------------------------------------------
resource "aws_launch_template" "main" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.web_security_group_id]

  user_data = local.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 required — prevents SSRF
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true # Detailed monitoring (1-min intervals)
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.cluster_name}-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${var.cluster_name}-volume"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-launch-template"
  })
}

# ---------------------------------------------------------------------------
# Auto Scaling Group
# ---------------------------------------------------------------------------
resource "aws_autoscaling_group" "main" {
  name_prefix = "${var.cluster_name}-"

  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]

  # CRITICAL: Use ELB health checks (not EC2) so ASG replaces unhealthy instances
  # that pass EC2 checks but fail ALB health checks (process running but not responding)
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # Instance refresh for zero-downtime rolling deployments
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  # Spread instances across AZs
  # availability_zone_rebalancing requires provider >= 6.x; omit for v5 compatibility

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity] # Let autoscaling manage this
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, {
      Name = "${var.cluster_name}-asg-instance"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# ---------------------------------------------------------------------------
# Auto Scaling Policies
# ---------------------------------------------------------------------------
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.cluster_name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.cluster_name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# Target tracking — automatically maintain average CPU at 60%
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.cluster_name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}


# =============================================================================
# MODULE: webserver-cluster
# Purpose: Reusable module that provisions a production-ready web server cluster
# consisting of an Auto Scaling Group (ASG) behind an Application Load Balancer
# (ALB). Callers pass in variables to customise size, instance type, ports, etc.
# =============================================================================


# -----------------------------------------------------------------------------
# DATA SOURCES
# We look up existing AWS infrastructure rather than hard-coding IDs.
# This keeps the module portable across accounts and regions.
# -----------------------------------------------------------------------------

# Fetch the default VPC in the current region.

resource "aws_launch_template" "webserver" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  description   = "user-data-hash-${md5(templatefile("${path.module}/user-data.sh", { server_port = var.server_port, cluster_name = var.cluster_name }))}"
}

# Fetch all subnets that belong to the default VPC.
# We spread the ASG and ALB across these subnets for high availability.

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# -----------------------------------------------------------------------------
# LAUNCH TEMPLATE
# Defines the blueprint for every EC2 instance the ASG will launch.
# Using a launch template (vs. launch configuration) gives us instance refresh,
# versioning, and IMDSv2 enforcement.
# -----------------------------------------------------------------------------
# AUTO SCALING GROUP (ASG)
# Manages the fleet of EC2 instances. Automatically replaces unhealthy instances
# and scales between min_size and max_size based on demand or polic


resource "aws_launch_template" "webserver" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami_id        # AMI passed in by the caller (default: Amazon Linux 2)
  instance_type = var.instance_type # e.g. t2.micro for dev, t2.medium for prod

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port  = var.server_port
    cluster_name = var.cluster_name
  }))

  vpc_security_group_ids = [aws_security_group.instance.id]

  metadata_options {
    http_endpoint               = "enabled"  # Keep metadata service on
    http_tokens                 = "required" # Force IMDSv2 — no token, no metadata
    http_put_response_hop_limit = 1          # Prevent metadata requests from leaving the instance
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.custom_tags, {
    Name = var.cluster_name
  })
}

lifecycle {
  create_before_destroy = true
}



# SCHEDULED SCALING — scale in at 7pm EAT, scale out at 8am EAT

resource "aws_autoscaling_schedule" "scale_in_evening" {
  scheduled_action_name  = "${var.cluster_name}-scale-in-7pm"
  autoscaling_group_name = aws_autoscaling_group.webserver.name
  recurrence             = "0 19 * * *" # 7:00 PM EAT daily
  min_size               = 1
  max_size               = var.max_size
  desired_capacity       = 1
}

resource "aws_autoscaling_schedule" "scale_out_morning" {
  scheduled_action_name  = "${var.cluster_name}-scale-out-8am"
  autoscaling_group_name = aws_autoscaling_group.webserver.name
  recurrence             = "0 8 * * *" # 8:00 AM EAT daily
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.min_size
}


resource "aws_autoscaling_policy" "scale_out" {
  count = var.enable_autoscaling ? 1 : 0

  name                   = "${var.cluster_name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.webserver.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}


# APPLICATION LOAD BALANCER


resource "aws_lb" "webserver" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

  tags = merge(var.custom_tags, {
    Name = var.cluster_name
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webserver.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "forward" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver.arn
  }
}

resource "aws_lb_target_group" "webserver" {
  name     = var.cluster_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# SECURITY GROUPS

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb"
  description = "Controls traffic to the Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(var.custom_tags, {
    Name = "${var.cluster_name}-alb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from internet"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-instance"
  description = "Controls traffic to individual EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(var.custom_tags, {
    Name = "${var.cluster_name}-instance"
  })
}

resource "aws_vpc_security_group_ingress_rule" "instance_from_alb" {
  security_group_id            = aws_security_group.instance.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
  description                  = "Allow traffic only from ALB"
}

resource "aws_vpc_security_group_egress_rule" "instance_all_out" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

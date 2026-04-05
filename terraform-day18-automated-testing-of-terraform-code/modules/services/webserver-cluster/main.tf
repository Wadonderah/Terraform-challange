##############################################################
# modules/services/webserver-cluster/main.tf
# Day 18: Automated Testing of Terraform Code
#
# This module is the subject of all three test layers:
#   Unit tests       → webserver_cluster_unit_test.tftest.hcl
#   Integration tests → test/webserver_cluster_test.go
#   End-to-end tests  → test/full_stack_e2e_test.go
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
}

##############################################################
# DATA SOURCES
# Fall back to the default VPC / subnets when vpc_id and
# subnet_ids are not supplied (common during unit/integration
# tests to avoid requiring a full networking module).
##############################################################

data "aws_vpc" "selected" {
  id      = var.vpc_id != "" ? var.vpc_id : null
  default = var.vpc_id == "" ? true : null
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

locals {
  # If subnet_ids were explicitly passed in, use them.
  # Otherwise fall back to whatever subnets exist in the VPC.
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.selected.ids
}

##############################################################
# SECURITY GROUP — ALB
# Inbound: HTTP on alb_port from anywhere
# Outbound: server_port to instance SG only
##############################################################

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for the ALB in cluster ${var.cluster_name}"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name        = "${var.cluster_name}-alb-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
    ClusterName = var.cluster_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow inbound HTTP"
  from_port         = var.alb_port
  to_port           = var.alb_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_instances" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to EC2 instances on server_port"
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.instance.id
}

##############################################################
# SECURITY GROUP — EC2 INSTANCE
# Inbound: server_port from ALB SG only
# Outbound: HTTPS for package updates
##############################################################

resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-instance-sg"
  description = "Security group for EC2 instances in cluster ${var.cluster_name}"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name        = "${var.cluster_name}-instance-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
    ClusterName = var.cluster_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "instance_from_alb" {
  security_group_id            = aws_security_group.instance.id
  description                  = "Allow traffic from ALB"
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "instance_https" {
  security_group_id = aws_security_group.instance.id
  description       = "Allow outbound HTTPS for package updates"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

##############################################################
# LAUNCH TEMPLATE
# IMDSv2 enforced. User data starts a minimal Python HTTP
# server that returns var.hello_world_text on port server_port.
##############################################################

locals {
  user_data = base64encode(<<-SCRIPT
    #!/bin/bash
    set -euo pipefail
    cat > /usr/local/bin/webserver.py << 'PYEOF'
    #!/usr/bin/env python3
    import http.server, socketserver, os
    PORT = int(os.environ.get("SERVER_PORT", "8080"))
    TEXT = os.environ.get("HELLO_TEXT", "Hello, World")
    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type","text/plain")
            self.end_headers()
            self.wfile.write((TEXT + "\n").encode())
        def log_message(self, *a): pass
    with socketserver.TCPServer(("", PORT), H) as s:
        s.serve_forever()
    PYEOF
    chmod +x /usr/local/bin/webserver.py
    cat > /etc/systemd/system/webserver.service << SVC
    [Unit]
    Description=Hello World Web Server
    After=network.target
    [Service]
    ExecStart=/usr/bin/python3 /usr/local/bin/webserver.py
    Restart=always
    Environment=SERVER_PORT=${var.server_port}
    Environment=HELLO_TEXT=${var.hello_world_text}
    [Install]
    WantedBy=multi-user.target
    SVC
    systemctl daemon-reload && systemctl enable webserver && systemctl start webserver
  SCRIPT
  )
}

resource "aws_launch_template" "example" {
  name_prefix            = "${var.cluster_name}-lt-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data              = local.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.cluster_name}-instance"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.cluster_name}-launch-template"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

##############################################################
# APPLICATION LOAD BALANCER
##############################################################

resource "aws_lb" "example" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.cluster_name}-alb"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_target_group" "example" {
  name                 = "${var.cluster_name}-tg"
  port                 = var.server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.selected.id
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/"
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
    Name        = "${var.cluster_name}-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  tags = {
    Name = "${var.cluster_name}-http-listener"
  }
}

##############################################################
# AUTO SCALING GROUP
##############################################################

resource "aws_autoscaling_group" "example" {
  name_prefix               = "${var.cluster_name}-"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.min_size
  vpc_zone_identifier       = local.subnet_ids
  target_group_arns         = [aws_lb_target_group.example.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-instance"
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

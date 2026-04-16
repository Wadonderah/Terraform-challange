locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "scalable-web-app"
  })
}

resource "aws_security_group" "instance" {
  name        = "web-instance-sg-${var.environment}"
  description = "Allow HTTP/HTTPS inbound to EC2 instances"
  vpc_id      = var.vpc_id

  # Allow HTTP from ALB security group (production-ready approach)
  dynamic "ingress" {
    for_each = var.alb_security_group_id != null ? [1] : []
    content {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [var.alb_security_group_id]
      description     = "Allow HTTP from ALB"
    }
  }

  # Fallback: Allow HTTP from anywhere (only if ALB SG not provided)
  dynamic "ingress" {
    for_each = var.alb_security_group_id == null ? [1] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from internet (dev only - not recommended)"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_launch_template" "web" {
  name_prefix   = "web-lt-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.instance.id]
  
user_data = base64encode(<<-USERDATA
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Wadonderah" > /var/www/html/index.html
USERDATA
)

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "web-${var.environment}" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

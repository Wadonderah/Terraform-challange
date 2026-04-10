# modules/compute/asg-rolling-deploy/main.tf
# Auto Scaling Group with zero-downtime rolling deployment
# Uses create_before_destroy so new instances are healthy before old ones terminate

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for EC2 instances in the ASG
resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-instance-sg"
  description = "Security group for ASG instances in ${var.cluster_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.cluster_name}-instance-sg"
    ManagedBy = "terraform"
  }
}

# Launch template — new resource version forces a new ASG rolling update
resource "aws_launch_template" "main" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami != "" ? var.ami : data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    environment = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "${var.cluster_name}-instance"
      ManagedBy = "terraform"
      Env       = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.cluster_name}-${aws_launch_template.main.latest_version}"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.min_size
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # Zero-downtime: create new instances before destroying old ones
  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = {
      Name      = "${var.cluster_name}-asg"
      ManagedBy = "terraform"
      Env       = var.environment
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Optional: scheduled scaling actions
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-out"
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.max_size
  recurrence             = "0 9 * * *"  # 9am UTC Mon-Fri
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-in"
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.min_size
  recurrence             = "0 17 * * *"  # 5pm UTC Mon-Fri
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# CloudWatch alarm — CPU high
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "CPU > 90% on ${var.cluster_name}"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = {
    ManagedBy = "terraform"
    Env       = var.environment
  }
}

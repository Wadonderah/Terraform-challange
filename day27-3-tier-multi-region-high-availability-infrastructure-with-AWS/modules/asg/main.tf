terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "multi-region-ha"
    Region      = var.region
  })
}

resource "aws_security_group" "instance" {
  name        = "web-instance-sg-${var.environment}-${var.region}"
  description = "Allow inbound HTTP from ALB only - no direct public access"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
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
  name_prefix   = "web-lt-${var.environment}-${var.region}-"
  image_id      = var.launch_template_ami
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

  # IMDSv2 enforced for security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== User-data script started at $(date) ==="

# Install httpd
yum update -y
yum install -y httpd

# Get metadata
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null) || TOKEN=""
if [ -n "$TOKEN" ]; then
  AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null) || AZ="unknown"
  INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null) || INSTANCE_ID="unknown"
else
  AZ="unknown"
  INSTANCE_ID="unknown"
fi

# Main application page — greeting for Wadonderah
cat > /var/www/html/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Wadonderah Multi-Region HA</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
    }
    .card {
      background: rgba(255,255,255,0.08);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(255,255,255,0.15);
      border-radius: 20px;
      padding: 50px 60px;
      max-width: 680px;
      text-align: center;
      box-shadow: 0 25px 50px rgba(0,0,0,0.4);
    }
    .greeting {
      font-size: 2.4rem;
      font-weight: 700;
      color: #e94560;
      margin-bottom: 10px;
      text-shadow: 0 0 30px rgba(233,69,96,0.5);
    }
    .sub {
      font-size: 1.1rem;
      color: #a8b2c1;
      margin-bottom: 30px;
    }
    .badge {
      display: inline-block;
      background: rgba(233,69,96,0.2);
      border: 1px solid #e94560;
      border-radius: 30px;
      padding: 6px 20px;
      font-size: 0.85rem;
      margin-bottom: 30px;
      color: #e94560;
      letter-spacing: 1px;
    }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 15px;
      margin-top: 25px;
      text-align: left;
    }
    .info-item {
      background: rgba(255,255,255,0.05);
      border-radius: 10px;
      padding: 15px;
    }
    .info-label { font-size: 0.75rem; color: #a8b2c1; text-transform: uppercase; letter-spacing: 1px; }
    .info-value { font-size: 1rem; font-weight: 600; color: #fff; margin-top: 4px; }
    .footer { margin-top: 30px; font-size: 0.8rem; color: #a8b2c1; }
    .dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; background: #22c55e; margin-right: 6px; animation: pulse 2s infinite; }
    @keyframes pulse { 0%%,100%%{opacity:1} 50%%{opacity:0.4} }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">🌍 MULTI-REGION HIGH AVAILABILITY</div>
    <div class="greeting">Hello Wadonderah</div>
    <div class="greeting" style="font-size:1.6rem; color:#f0a500;">its nice to see you back</div>
    <p class="sub">Your 3-Tier Multi-Region HA infrastructure is running perfectly.</p>
    <div class="info-grid">
      <div class="info-item">
        <div class="info-label">Region</div>
        <div class="info-value">${var.region}</div>
      </div>
      <div class="info-item">
        <div class="info-label">Availability Zone</div>
        <div class="info-value">$AZ</div>
      </div>
      <div class="info-item">
        <div class="info-label">Instance ID</div>
        <div class="info-value" style="font-size:0.85rem;">$INSTANCE_ID</div>
      </div>
      <div class="info-item">
        <div class="info-label">Environment</div>
        <div class="info-value">${var.environment}</div>
      </div>
    </div>
    <div class="footer">
      <span class="dot"></span> Live · 30-Day Terraform Challenge Day 27
    </div>
  </div>
</body>
</html>
HTMLEOF

# Create health check endpoint
mkdir -p /var/www/html
echo "OK" > /var/www/html/health

# Start and enable httpd
systemctl enable httpd
systemctl start httpd

echo "=== User-data script completed at $(date) ==="
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "web-${var.environment}-${var.region}" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Auto Scaling Group ────────────────────────────────────────────────────────
resource "aws_autoscaling_group" "web" {
  name                = "web-asg-${var.environment}-${var.region}"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  dynamic "tag" {
    for_each = merge(local.common_tags, { Name = "web-${var.environment}-${var.region}" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Scale-out policy ──────────────────────────────────────────────────────────
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "web-scale-out-${var.environment}-${var.region}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# ── Scale-in policy ───────────────────────────────────────────────────────────
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "web-scale-in-${var.environment}-${var.region}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# ── CloudWatch: CPU high → scale out ─────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "web-cpu-high-${var.environment}-${var.region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_scale_out_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Scale out when average CPU >= ${var.cpu_scale_out_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]
}

# ── CloudWatch: CPU low → scale in ───────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "web-cpu-low-${var.environment}-${var.region}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_scale_in_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Scale in when average CPU <= ${var.cpu_scale_in_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_in.arn]
}

# ==============================================================================
# Webserver Cluster Module - Main Infrastructure
# ==============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Data Sources
# ─────────────────────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# VPC and Networking
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Groups
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

resource "aws_security_group" "webserver" {
  name        = "${var.cluster_name}-webserver-sg"
  description = "Security group for webserver instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-webserver-sg"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Application Load Balancer
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_lb" "webserver" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.cluster_name}-alb"
  }
}

resource "aws_lb_target_group" "webserver" {
  name     = "${var.cluster_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name = "${var.cluster_name}-tg"
  }
}

resource "aws_lb_listener" "webserver" {
  load_balancer_arn = aws_lb.webserver.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver.arn
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Launch Template
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_launch_template" "webserver" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.webserver.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              
              # Create a simple web page
              cat > /var/www/html/index.html <<'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>${var.cluster_name}</title>
                  <style>
                      body {
                          font-family: Arial, sans-serif;
                          max-width: 800px;
                          margin: 50px auto;
                          padding: 20px;
                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                          color: white;
                      }
                      .container {
                          background: rgba(255, 255, 255, 0.1);
                          padding: 30px;
                          border-radius: 10px;
                          backdrop-filter: blur(10px);
                      }
                      h1 { margin-top: 0; }
                      .info { margin: 20px 0; }
                      .label { font-weight: bold; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🚀 ${var.cluster_name}</h1>
                      <div class="info">
                          <p><span class="label">Instance ID:</span> $(ec2-metadata --instance-id | cut -d " " -f 2)</p>
                          <p><span class="label">Availability Zone:</span> $(ec2-metadata --availability-zone | cut -d " " -f 2)</p>
                          <p><span class="label">Local IP:</span> $(ec2-metadata --local-ipv4 | cut -d " " -f 2)</p>
                          <p><span class="label">Hostname:</span> $(hostname)</p>
                      </div>
                      <p>✅ Webserver is running successfully!</p>
                      <p>📊 Monitored by CloudWatch alarms</p>
                  </div>
              </body>
              </html>
              HTML
              
              # Configure httpd to listen on port 8080
              sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
              systemctl restart httpd
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Auto Scaling Group
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_autoscaling_group" "webserver" {
  name                      = "${var.cluster_name}-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = aws_subnet.public[*].id
  target_group_arns         = [aws_lb_target_group.webserver.arn]

  launch_template {
    id      = aws_launch_template.webserver.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Auto Scaling Policies (Optional - for demonstration)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.cluster_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.webserver.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.cluster_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.webserver.name
}
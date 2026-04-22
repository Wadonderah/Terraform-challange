# =============================================================================
# modules/compute/main.tf
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: count meta-argument
# count creates multiple instances of the same resource.
# Each instance is addressed as: aws_instance.this[0], aws_instance.this[1]
# In state: module.compute.aws_instance.this[0]
#
# EXAM CONCEPT: Immutable infrastructure practice
# To replace an instance without changing config:
#   terraform apply -replace=module.compute.aws_instance.this[0]
# This destroys and recreates the instance - immutable replacement.
# =============================================================================

resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Security group for web servers - Day 28 exam prep"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-web-sg" })
}

resource "aws_instance" "this" {
  count = var.instance_count

  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.web.id]

  # EXAM CONCEPT: Immutable infrastructure
  # user_data changes force instance replacement (immutable).
  # Terraform does not patch running instances in place.
  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Day 28 Terraform Challenge - Instance ${count.index + 1}</h1>" > /var/www/html/index.html
  USERDATA
  )

  tags = merge(var.tags, {
    Name  = "${var.name}-web-${count.index + 1}"
    Index = tostring(count.index)
  })

  # EXAM CONCEPT: lifecycle rules
  # create_before_destroy ensures a new instance is running before the old
  # one is terminated - useful for zero-downtime replacements.
  lifecycle {
    create_before_destroy = true
  }
}
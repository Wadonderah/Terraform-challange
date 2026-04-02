##############################################################
# modules/security/main.tf
# Creates security groups for ALB and EC2 instances
# IMPORTANT: Rules are explicit — no extras, no missing rules
##############################################################

##############################################################
# ALB SECURITY GROUP
# Inbound:  HTTP (80) from the internet
# Outbound: HTTP (server_port) to EC2 instances only
##############################################################

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# Allow inbound HTTP from the internet
resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow inbound HTTP from internet"
  from_port         = var.alb_port
  to_port           = var.alb_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-http-in"
  }
}

# Allow outbound to EC2 instances on server_port
resource "aws_vpc_security_group_egress_rule" "alb_to_instances" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow outbound to EC2 instances on server port"
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.instance.id

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-to-instances"
  }
}

##############################################################
# EC2 INSTANCE SECURITY GROUP
# Inbound:  server_port from ALB only
# Outbound: HTTPS (443) for package downloads; nothing else
##############################################################

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-${var.environment}-instance-sg"
  description = "Security group for EC2 instances in the ASG"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-sg"
  }
}

# Allow inbound from ALB only on server_port
resource "aws_vpc_security_group_ingress_rule" "instance_from_alb" {
  security_group_id            = aws_security_group.instance.id
  description                  = "Allow inbound from ALB on server port"
  from_port                    = var.server_port
  to_port                      = var.server_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-from-alb"
  }
}

# Allow outbound HTTPS for package updates and AWS API calls
resource "aws_vpc_security_group_egress_rule" "instance_https_out" {
  security_group_id = aws_security_group.instance.id
  description       = "Allow outbound HTTPS for package updates and AWS APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-https-out"
  }
}

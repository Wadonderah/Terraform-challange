data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = var.db_name
  subnet_ids = data.aws_subnets.default.ids

  tags = merge(var.custom_tags, {
    Name = var.db_name
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.db_name}-rds"
  description = "Controls access to the RDS instance"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(var.custom_tags, {
    Name = "${var.db_name}-rds"
  })
}

resource "aws_vpc_security_group_ingress_rule" "mysql" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
  description       = "Allow MySQL from within the VPC only"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

resource "aws_db_instance" "default" {
  identifier             = var.db_name
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  multi_az                = false
  publicly_accessible     = false
  storage_encrypted       = true

  tags = merge(var.custom_tags, {
    Name = var.db_name
  })
}

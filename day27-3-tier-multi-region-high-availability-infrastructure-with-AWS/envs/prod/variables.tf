variable "app_name" {
  description = "Application name — used as a naming prefix across all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

# ── EC2 ───────────────────────────────────────────────────────────────────────
variable "primary_ami_id" {
  description = "Amazon Linux 2023 AMI ID for us-east-1"
  type        = string
}

variable "secondary_ami_id" {
  description = "Amazon Linux 2023 AMI ID for us-west-2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum ASG instance count"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum ASG instance count"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired ASG instance count at launch"
  type        = number
  default     = 2
}

# ── Primary VPC ───────────────────────────────────────────────────────────────
variable "primary_vpc_cidr" {
  description = "CIDR block for the primary region VPC"
  type        = string
}

variable "primary_public_subnet_cidrs" {
  description = "Public subnet CIDRs in primary region (one per AZ)"
  type        = list(string)
}

variable "primary_private_subnet_cidrs" {
  description = "Private subnet CIDRs in primary region (one per AZ)"
  type        = list(string)
}

variable "primary_availability_zones" {
  description = "AZs to use in the primary region"
  type        = list(string)
}

# ── Secondary VPC ─────────────────────────────────────────────────────────────
variable "secondary_vpc_cidr" {
  description = "CIDR block for the secondary region VPC"
  type        = string
}

variable "secondary_public_subnet_cidrs" {
  description = "Public subnet CIDRs in secondary region (one per AZ)"
  type        = list(string)
}

variable "secondary_private_subnet_cidrs" {
  description = "Private subnet CIDRs in secondary region (one per AZ)"
  type        = list(string)
}

variable "secondary_availability_zones" {
  description = "AZs to use in the secondary region"
  type        = list(string)
}

# ── RDS ───────────────────────────────────────────────────────────────────────
variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password — store in AWS Secrets Manager in real production"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# ── Route53 ───────────────────────────────────────────────────────────────────
variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for your domain"
  type        = string
}

variable "domain_name" {
  description = "FQDN for the application (e.g. app.wadonderah.com)"
  type        = string
}

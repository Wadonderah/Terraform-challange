# =============================================================================
# modules/compute/variables.tf
# Day 28: Terraform Associate Exam Prep
# =============================================================================

variable "name"           { description = "Name prefix."                         ; type = string }
variable "instance_type"  { description = "EC2 instance type."                   ; type = string ; default = "t3.micro" }
variable "instance_count" { description = "Number of instances."                 ; type = number ; default = 1 }
variable "ami_id"         { description = "AMI ID."                              ; type = string }
variable "subnet_id"      { description = "Subnet to launch instances into."     ; type = string }
variable "vpc_id"         { description = "VPC ID for security group."           ; type = string }
variable "tags"           { description = "Resource tags."                       ; type = map(string) ; default = {} }
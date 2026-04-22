variable "name" { description = "Name prefix." ; type = string }
variable "vpc_cidr" { description = "VPC CIDR block." ; type = string }
variable "public_subnet_cidrs" { description = "Public subnet CIDRs." ; type = list(string) }
variable "private_subnet_cidrs" { description = "Private subnet CIDRs." ; type = list(string) }
variable "availability_zones" { description = "AZs for subnets." ; type = list(string) }
variable "tags" { description = "Resource tags." ; type = map(string) ; default = {} }
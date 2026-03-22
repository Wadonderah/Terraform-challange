
variable "environment" {
  type    = string
  default = "staging"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}


variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

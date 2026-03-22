
variable "environment" {
  type    = string
  default = "production"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}


variable "vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

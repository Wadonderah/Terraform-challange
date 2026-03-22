variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 80
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami" {
  description = "The AMI ID for the EC2 instance (Amazon Linux 2023, us-east-1)"
  type        = string
  default     = "ami-02dfbd4ff395f2a1b"
}

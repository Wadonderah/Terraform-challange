##############################################################
# environments/prod/terraform.tfvars
# Production environment — larger instances, more replicas
##############################################################

environment          = "prod"
aws_region           = "us-east-1"
project_name         = "webserver-cluster"
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
instance_type        = "t3.small"
ami_id               = "ami-0c02fb55956c7d316" # Amazon Linux 2023 us-east-1
asg_min_size         = 2
asg_max_size         = 6
asg_desired_capacity = 2
server_port          = 80
alb_port             = 80
health_check_path    = "/"
hello_world_version  = "v2"

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}

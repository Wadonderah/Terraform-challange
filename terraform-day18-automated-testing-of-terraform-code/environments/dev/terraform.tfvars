##############################################################
# environments/dev/terraform.tfvars
##############################################################

environment      = "dev"
cluster_name     = "webserver-cluster-dev"
instance_type    = "t3.micro"
min_size         = 1
max_size         = 2
hello_world_text = "Hi Wadondera welcome back!"
ami_id           = "ami-0c02fb55956c7d316" # Amazon Linux 2023 us-east-1 — update if deploying to another region

##############################################################
# environments/prod/terraform.tfvars
##############################################################

environment      = "prod"
cluster_name     = "webserver-cluster-prod"
instance_type    = "t3.small"
min_size         = 2
max_size         = 6
hello_world_text = "Hi Wadondera welcome back!"
ami_id           = "ami-0c02fb55956c7d316" # Amazon Linux 2023 us-east-1 — update if deploying to another region

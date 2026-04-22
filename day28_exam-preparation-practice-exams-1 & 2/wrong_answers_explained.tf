# =============================================================================
# wrong_answers_explained.tf
# Day 28: Terraform Associate Exam Prep - Wrong Answer Analysis in HCL
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# This file is NOT meant to be applied. It is a learning document written in
# Terraform HCL syntax. Each section maps to a wrong answer from the Day 28
# practice exams and demonstrates the correct behaviour with real code.
# =============================================================================

# =============================================================================
# WRONG ANSWER 1: Q4 Topic 1 - Immutable Infrastructure Advantage
#
# Question: What is an advantage of immutable infrastructure?
# My answer: C - Quicker infrastructure upgrades
# Correct:   D - Less complex infrastructure upgrades
#
# Explanation:
# Immutable infrastructure replaces resources instead of modifying them.
# This eliminates configuration drift and partial upgrade states.
# The PRIMARY advantage is LESS COMPLEXITY, not speed.
# Quicker is sometimes true but is not the defining characteristic.
#
# The code below demonstrates immutable replacement:
# =============================================================================

# MUTABLE approach (what we avoid):
# In-place update - risky, can leave resource in partial state
# resource "aws_instance" "mutable_example" {
#   ami           = "ami-old"
#   instance_type = "t2.micro"
#   # If you change the AMI, Terraform must destroy and recreate the instance.
#   # You cannot patch the AMI in place on a running EC2 instance.
# }

# IMMUTABLE approach (Terraform default):
# To "upgrade" this instance, change the AMI and run terraform apply.
# Terraform will REPLACE the instance (destroy + create), not patch it.
# This is the immutable pattern. It is less complex because:
#   - No partial state possible
#   - No configuration drift
#   - New instance is fully known before old one is terminated (with create_before_destroy)
resource "aws_instance" "immutable_example" {
  ami           = "ami-0c55b159cbfafe1f0" # Change this to trigger replacement
  instance_type = "t3.micro"
  subnet_id     = "subnet-placeholder"

  lifecycle {
    # create_before_destroy is the immutable pattern in action:
    # New instance is running and verified before old one is terminated.
    create_before_destroy = true

    # replace_triggered_by forces replacement when a referenced resource changes.
    # Another example of immutable infrastructure in Terraform.
    # replace_triggered_by = [aws_security_group.web]
  }

  tags = { Name = "immutable-example" }
}

# To force immutable replacement of a specific instance:
# terraform apply -replace=aws_instance.immutable_example


# =============================================================================
# WRONG ANSWER 2: terraform state rm vs terraform destroy
#
# My mistake: Believed terraform state rm destroys the actual cloud resource.
# Correct:    terraform state rm removes from state only. Resource survives.
#
# terraform state rm -> resource becomes unmanaged orphan in AWS
# terraform destroy  -> resource is deleted from both state AND AWS
# =============================================================================

# After terraform apply creates this bucket, run:
#   terraform state rm aws_s3_bucket.state_rm_demo
#   aws s3 ls | grep state-rm-demo   <- bucket still exists
#   terraform state list             <- bucket not in state
#   terraform destroy                <- would NOT delete the bucket (not in state)
resource "aws_s3_bucket" "state_rm_demo" {
  bucket = "day28-state-rm-demo-example"
  tags   = { Name = "state-rm-demo", Purpose = "wrong-answer-2-demo" }
}


# =============================================================================
# WRONG ANSWER 3: Module source - version argument support
#
# My mistake: Said all module sources support the version argument.
# Correct:    Only registry sources support version.
#             Local paths: use path directly, no version
#             Git sources: use ?ref= in the URL, no version argument
# =============================================================================

# CORRECT: Registry source supports version argument
module "vpc_registry" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1" # VALID: registry sources support version

  name = "registry-vpc-example"
  cidr = "10.0.0.0/16"
  azs  = ["us-east-1a"]
}

# CORRECT: Local source - no version argument
module "vpc_local" {
  source = "./modules/vpc" # VALID: local path, no version argument

  # version = "1.0.0"  # ERROR: version not allowed for local module sources

  name                 = "local-vpc-example"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24"]
  availability_zones   = ["us-east-1a"]
}

# CORRECT: Git source - use ref= not version
# module "vpc_git" {
#   source = "git::https://github.com/org/terraform-vpc.git?ref=v1.2.0"
#   # version = "1.2.0"  # ERROR: version not allowed for git sources
# }


# =============================================================================
# WRONG ANSWER 4: sensitive = true does NOT encrypt state
#
# My mistake: Assumed sensitive = true encrypts the value in terraform.tfstate.
# Correct:    sensitive = true suppresses display in CLI output ONLY.
#             The value is stored in PLAINTEXT in terraform.tfstate.
#
# To see this yourself after apply:
#   terraform output db_password          # shows: (sensitive value)
#   terraform output -json db_password    # shows: "actual-plaintext-value"
#   cat terraform.tfstate | grep db_password -A2  # plaintext in state
# =============================================================================

variable "demo_secret" {
  description = "Demo secret value. sensitive=true suppresses CLI display only."
  type        = string
  sensitive   = true
  default     = "this-is-plaintext-in-tfstate"
}

output "demo_sensitive_output" {
  description = <<-EOT
    EXAM REMINDER:
    - terraform output demo_sensitive_output  -> shows (sensitive value)
    - terraform output -json demo_sensitive_output  -> shows plaintext
    - cat terraform.tfstate  -> plaintext stored here regardless
    sensitive=true is a display control, NOT encryption.
  EOT
  value     = var.demo_secret
  sensitive = true
}


# =============================================================================
# WRONG ANSWER 5: terraform refresh updates STATE not configuration files
#
# My mistake: Thought terraform refresh updates .tf configuration files.
# Correct:    terraform refresh reads real infrastructure and updates the
#             STATE FILE only. Configuration files (.tf) are NEVER modified
#             by any Terraform command.
#
# terraform refresh  -> state updated to match real infra
# .tf files          -> unchanged. Only a human editor changes these.
# =============================================================================

# If someone manually changes an EC2 instance tag in the AWS console
# (e.g., renames it from "web-1" to "web-1-manual-edit"),
# terraform refresh will update the state file to reflect the manual change.
# The tags block in this resource definition (.tf file) is NOT changed.
# Running terraform plan after refresh would show the drift.
resource "aws_instance" "refresh_demo" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  subnet_id     = "subnet-placeholder"

  tags = {
    Name    = "refresh-demo"
    # If you change this tag manually in AWS console, terraform refresh
    # will detect it in state. The .tf file is still "refresh-demo".
    # terraform plan will then show: ~ tags.Name = "manual-edit" -> "refresh-demo"
  }
}
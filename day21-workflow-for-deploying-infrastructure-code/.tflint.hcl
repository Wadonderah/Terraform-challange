# TFLint Configuration
# Provider-aware linting for Terraform code
# See: https://github.com/terraform-linters/tflint

config {
  # Enable module inspection
  module = true
  
  # Force exit code 0 even when issues are found (for CI flexibility)
  force = false
  
  # Disable color output in CI environments
  disabled_by_default = false
}

# AWS Plugin Configuration
plugin "aws" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Terraform Plugin Configuration
plugin "terraform" {
  enabled = true
  version = "0.5.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

# ──────────────────────────────────────────────────────────────────
# AWS-Specific Rules
# ──────────────────────────────────────────────────────────────────

# Enforce valid instance types
rule "aws_instance_invalid_type" {
  enabled = true
}

# Prevent previous generation instance types
rule "aws_instance_previous_type" {
  enabled = true
}

# Enforce valid AMI IDs
rule "aws_instance_invalid_ami" {
  enabled = true
}

# Enforce valid IAM policy documents
rule "aws_iam_policy_invalid_policy" {
  enabled = true
}

# Enforce valid S3 bucket names
rule "aws_s3_bucket_invalid_bucket_name" {
  enabled = true
}

# Enforce valid security group rules
rule "aws_security_group_invalid_protocol" {
  enabled = true
}

# Enforce valid ALB/NLB configurations
rule "aws_alb_invalid_security_group" {
  enabled = true
}

rule "aws_alb_invalid_subnet" {
  enabled = true
}

# Enforce valid RDS configurations
rule "aws_db_instance_invalid_type" {
  enabled = true
}

rule "aws_db_instance_previous_type" {
  enabled = true
}

# ──────────────────────────────────────────────────────────────────
# Terraform Best Practices
# ──────────────────────────────────────────────────────────────────

# Require variable descriptions
rule "terraform_documented_variables" {
  enabled = true
}

# Require output descriptions
rule "terraform_documented_outputs" {
  enabled = true
}

# Enforce naming conventions
rule "terraform_naming_convention" {
  enabled = true
  
  # Variable naming
  variable {
    format = "snake_case"
  }
  
  # Output naming
  output {
    format = "snake_case"
  }
  
  # Resource naming
  resource {
    format = "snake_case"
  }
  
  # Module naming
  module {
    format = "snake_case"
  }
}

# Require module version pinning
rule "terraform_module_pinned_source" {
  enabled = true
  style   = "semver"
}

# Enforce standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Require type constraints on variables
rule "terraform_typed_variables" {
  enabled = true
}

# Prevent unused declarations
rule "terraform_unused_declarations" {
  enabled = true
}

# Require workspace usage for multi-environment
rule "terraform_workspace_remote" {
  enabled = false  # Disabled - we use workspaces locally
}

# Prevent deprecated syntax
rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Enforce required providers block
rule "terraform_required_providers" {
  enabled = true
}

# Enforce required version constraints
rule "terraform_required_version" {
  enabled = true
}

# ──────────────────────────────────────────────────────────────────
# Custom Rules (Disabled by Default)
# ──────────────────────────────────────────────────────────────────

# Enforce comment style
rule "terraform_comment_syntax" {
  enabled = false  # Can be noisy
}

# Enforce map/list syntax
rule "terraform_map_duplicate_keys" {
  enabled = true
}
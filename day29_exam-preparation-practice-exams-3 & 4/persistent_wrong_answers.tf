# =============================================================================
# persistent_wrong_answers.tf
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# PURPOSE: Every topic that appeared in wrong answers across MORE THAN ONE
# exam is documented here as executable HCL — proving understanding through
# code, not just reading.
# =============================================================================

# =============================================================================
# PERSISTENT GAP 1: terraform state rm vs terraform destroy vs terraform import
#
# Appeared wrong in: Exam 1, Exam 2, Exam 3
#
# My own words explanation (written before checking docs):
#   terraform state rm:   removes a resource from Terraform's state file.
#                         The real cloud resource keeps running. It becomes
#                         an orphan — unmanaged by Terraform.
#   terraform destroy:    removes the resource from state AND deletes the
#                         actual cloud resource. Real infrastructure is gone.
#   terraform import:     reads an existing cloud resource and adds it to
#                         state. It does NOT generate .tf configuration.
#                         After import, terraform plan will show differences
#                         until your .tf config matches the real resource.
#   terraform refresh:    reads real infrastructure and updates state to match.
#                         Does NOT modify .tf configuration files. Ever.
# =============================================================================

resource "random_id" "state_practice" {
  byte_length = 4

  # After terraform apply, practice:
  #
  # terraform state list
  #   -> random_id.state_practice
  #
  # terraform state show random_id.state_practice
  #   -> shows hex, dec, b64 values
  #
  # terraform state rm random_id.state_practice
  #   -> removed from state; random_id still "exists" conceptually
  #   -> terraform state list shows nothing
  #   -> terraform apply would create a NEW random_id (different value)
  #
  # terraform destroy
  #   -> removes from state AND the resource ceases to exist
  #   -> for random_id: the value is gone permanently
}

locals {
  state_command_matrix = {
    "terraform state rm" = {
      modifies_state          = true
      deletes_real_resource   = false
      generates_tf_config     = false
      exam_summary            = "Orphans the resource. State removed, infra survives."
    }
    "terraform destroy" = {
      modifies_state          = true
      deletes_real_resource   = true
      generates_tf_config     = false
      exam_summary            = "Destroys everything. State removed AND infra deleted."
    }
    "terraform import" = {
      modifies_state          = true
      deletes_real_resource   = false
      generates_tf_config     = false   # EXAM TRAP
      exam_summary            = "Adds existing resource to state. Does NOT write .tf config."
      post_import_behaviour   = "terraform plan shows differences until .tf matches real resource"
    }
    "terraform refresh" = {
      modifies_state          = true
      modifies_tf_config      = false   # EXAM TRAP
      deletes_real_resource   = false
      exam_summary            = "Updates state to match real infra. Never touches .tf files."
      modern_equivalent       = "terraform apply -refresh-only (Terraform >= 0.15.4)"
    }
    "terraform state mv" = {
      modifies_state          = true
      deletes_real_resource   = false
      generates_tf_config     = false
      exam_summary            = "Renames resource address in state. Infra unchanged."
    }
  }
}

output "state_command_matrix" {
  description = "State command comparison matrix. Query with: terraform output state_command_matrix"
  value       = local.state_command_matrix
}

# =============================================================================
# PERSISTENT GAP 2: State locking behaviour
#
# Appeared wrong in: Exam 2, Exam 4
#
# My own words:
#   State locking acquires a lock on the state file when an APPLY starts.
#   It prevents two operators from running apply simultaneously.
#   It does NOT prevent concurrent plan operations — plan is read-only.
#   If an apply crashes, you may need: terraform force-unlock <lock-id>
# =============================================================================

locals {
  state_locking_facts = {
    what_is_locked      = "State file (via DynamoDB for S3 backend, Terraform Cloud built-in)"
    when_locked         = "During apply and state-modifying operations"
    when_NOT_locked     = "During plan (plan is read-only, does not modify state)"
    concurrent_plans    = "Allowed — two operators can terraform plan simultaneously"
    concurrent_applies  = "Blocked — second apply waits or errors with lock info"
    lock_backend_s3     = "Requires DynamoDB table with LockID hash key"
    lock_backend_cloud  = "Built into Terraform Cloud, no extra config needed"
    force_unlock        = "terraform force-unlock <lock-id>  — use with caution"
    exam_trap           = "State locking prevents concurrent apply, NOT concurrent plan"
  }
}

output "state_locking_facts" {
  description = "State locking behaviour for exam review."
  value       = local.state_locking_facts
}

# =============================================================================
# PERSISTENT GAP 3: Terraform workflow command order
#
# Appeared wrong in: Exam 3, Exam 4
#
# My own words:
#   init     -> downloads providers and modules, sets up backend
#   validate -> checks syntax and internal consistency (requires init)
#   plan     -> shows what apply would do (does not change infra)
#   apply    -> executes the plan and changes infra
#   destroy  -> destroys all managed resources
#
#   fmt      -> reformats .tf files (can run at any point, does not affect infra)
#   refresh  -> updates state to match real infra (modern: apply -refresh-only)
#
# EXAM TRAP: terraform validate requires init to have run first.
# Providers must be installed for validate to check provider-specific syntax.
# You CANNOT run validate in a fresh directory without running init first.
# =============================================================================

locals {
  workflow_order = [
    {
      step    = 1
      command = "terraform init"
      purpose = "Download providers/modules, configure backend"
      requires = "Nothing (first command)"
      changes_infra = false
    },
    {
      step    = 2
      command = "terraform validate"
      purpose = "Check syntax and internal consistency"
      requires = "terraform init must have run first"
      changes_infra = false
      exam_trap = "Cannot run in a fresh directory — providers must be installed"
    },
    {
      step    = 3
      command = "terraform plan"
      purpose = "Show what apply would do. Diff between config and state."
      requires = "terraform init"
      changes_infra = false
    },
    {
      step    = 4
      command = "terraform apply"
      purpose = "Execute changes and update state"
      requires = "terraform init, provider credentials"
      changes_infra = true
    },
    {
      step    = 5
      command = "terraform destroy"
      purpose = "Destroy all managed resources"
      requires = "terraform init, provider credentials"
      changes_infra = true
    },
  ]

  special_commands = {
    "terraform fmt" = {
      when     = "Any time — does not affect providers or infra"
      purpose  = "Reformat .tf files to canonical style"
      safe     = true
    }
    "terraform refresh" = {
      when          = "After manual changes to real infra"
      purpose       = "Update state to match real infra"
      modern_form   = "terraform apply -refresh-only (Terraform >= 0.15.4)"
      safe          = "Does not change real infra, only state"
    }
  }
}

output "workflow_order" {
  description = "Correct Terraform workflow command order."
  value       = local.workflow_order
}
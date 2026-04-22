# =============================================================================
# workspace_demo.tf
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Terraform CLI Workspaces
#
# PERSISTENT WRONG ANSWER: Terraform Cloud workspaces = CLI workspaces
# CORRECT: They are completely different concepts.
#
# CLI WORKSPACES:
#   - Multiple isolated state files within the SAME backend configuration
#   - Same .tf configuration, different state
#   - terraform.workspace returns current workspace name as a string
#   - "default" workspace always exists, CANNOT be deleted
#   - State locking prevents concurrent apply, NOT concurrent plan
#
# TERRAFORM CLOUD WORKSPACES:
#   - Separate entities with their own variables, runs, permissions, state
#   - Think: separate projects, not separate branches of the same project
#   - Each has its own execution mode (local/remote/agent)
#   - Managed via TF Cloud UI/API, not terraform workspace CLI commands
# =============================================================================

locals {
  # terraform.workspace is a built-in string — the current workspace name
  # When you run: terraform workspace select staging
  # local.workspace_name = "staging"
  workspace_name = terraform.workspace

  # EXAM: terraform.workspace is always a string.
  # Use it to drive conditional logic or naming.
  is_production = local.workspace_name == "prod"

  workspace_concepts = {
    current_workspace = terraform.workspace

    cli_workspace_facts = {
      built_in_variable    = "terraform.workspace returns current workspace as string"
      default_workspace    = "Always named 'default', cannot be deleted"
      state_isolation      = "Each workspace has its own state file in the backend"
      same_config          = "All workspaces share the same .tf configuration files"
      state_locking        = "Locks during apply only, NOT during plan"
      list_command         = "terraform workspace list"
      new_command          = "terraform workspace new <name>"
      select_command       = "terraform workspace select <name>"
      delete_command       = "terraform workspace delete <name> (must not be current)"
      show_command         = "terraform workspace show"
    }

    tf_cloud_workspace_facts = {
      isolation            = "Completely separate: own state, vars, runs, permissions"
      not_same_as_cli      = "terraform workspace new does NOT create a TF Cloud workspace"
      execution_modes      = "local, remote, or agent — per workspace"
      managed_by           = "TF Cloud UI or API, not CLI workspace commands"
      use_case             = "Separate environments that need separate access control"
    }

    exam_trap = {
      wrong = "Terraform Cloud workspaces and CLI workspaces are the same thing"
      right = "They share the word 'workspace' but are completely different concepts"
    }
  }
}

output "workspace_concepts" {
  description = "Workspace concept comparison for exam review."
  value       = local.workspace_concepts
}

output "current_workspace" {
  description = "The active Terraform workspace. Run: terraform workspace select <name> to change."
  value       = terraform.workspace
}
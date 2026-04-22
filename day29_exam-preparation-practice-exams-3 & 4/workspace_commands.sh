#!/bin/bash
# =============================================================================
# workspace_commands.sh
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# Run this script to practice all Terraform workspace commands.
# =============================================================================

echo "=================================================================="
echo "Day 29 - Workspace Practice"
echo "30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps"
echo "=================================================================="

echo ""
echo "--- 1. LIST: Show all workspaces ---"
terraform workspace list
echo "(asterisk marks the current workspace)"
echo "EXAM: 'default' workspace always exists and CANNOT be deleted."

echo ""
echo "--- 2. SHOW: Display current workspace name ---"
terraform workspace show
echo "EXAM: terraform.workspace in your .tf files returns this string value."

echo ""
echo "--- 3. NEW: Create new workspaces ---"
terraform workspace new dev     2>/dev/null || echo "workspace 'dev' already exists"
terraform workspace new staging 2>/dev/null || echo "workspace 'staging' already exists"
echo "Created: dev, staging"

echo ""
echo "--- 4. SELECT: Switch to a workspace ---"
terraform workspace select dev
echo "Now on workspace: $(terraform workspace show)"
echo "EXAM: Each workspace has its own separate state file in the backend."
echo "      Switching workspace changes which state file Terraform reads/writes."

echo ""
echo "--- 5. LIST again: See all workspaces ---"
terraform workspace list

echo ""
echo "--- 6. terraform.workspace value in current context ---"
echo "The .tf files will see terraform.workspace = '$(terraform workspace show)'"
echo "This can drive conditional logic in locals.tf and resource naming."

echo ""
echo "--- 7. DELETE: Remove a workspace ---"
terraform workspace select default
terraform workspace delete staging 2>/dev/null || echo "(staging already deleted or doesn't exist)"
echo "EXAM: You cannot delete the workspace you are currently on."
echo "      You cannot delete the 'default' workspace — ever."

echo ""
echo "--- 8. Back to default ---"
terraform workspace select default
echo "Back on: $(terraform workspace show)"

echo ""
echo "=================================================================="
echo "Workspace practice complete."
echo ""
echo "KEY EXAM DISTINCTIONS:"
echo "  CLI workspaces: same config, multiple state files in same backend"
echo "  TF Cloud workspaces: separate entities (vars, runs, permissions, state)"
echo "  terraform.workspace: built-in string, NOT a variable you can set in tfvars"
echo "  default workspace: always exists, cannot be deleted"
echo "  state locking: applies during APPLY only, NOT during plan"
echo "=================================================================="
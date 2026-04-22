#!/bin/bash
# =============================================================================
# state_commands.sh
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# Run AFTER terraform apply to practice every state command tested in the exam.
# =============================================================================
set -e

echo "=================================================================="
echo "Day 29 - State Management Practice"
echo "30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps"
echo "=================================================================="

echo ""
echo "--- 1. LIST: All resources Terraform knows about ---"
terraform state list
echo "(reads state file only — does not contact AWS)"

echo ""
echo "--- 2. SHOW: Inspect a specific resource in detail ---"
terraform state show module.random_demo.random_id.this || echo "(resource may not exist yet — run terraform apply first)"

echo ""
echo "--- 3. MV: Rename resource address in state (infra unchanged) ---"
# terraform state mv renames an address. Real resource is untouched.
# EXAM: state mv does NOT change infra, only the state file address.
echo "Would run: terraform state mv module.random_demo.null_resource.state_practice module.random_demo.null_resource.renamed"
echo "Effect: address renamed in state. null_resource still exists."

echo ""
echo "--- 4. RM: Remove from state WITHOUT destroying ---"
# EXAM TRAP: state rm != destroy
# state rm -> resource removed from state, infra SURVIVES as unmanaged orphan
# destroy  -> resource removed from state AND deleted from real infrastructure
echo "Would run: terraform state rm module.random_demo.null_resource.state_practice"
echo "Effect: resource gone from state. null_resource still 'exists' conceptually."
echo "CONTRAST: terraform destroy would delete the actual resource."

echo ""
echo "--- 5. PULL: View raw state JSON ---"
echo "Running: terraform state pull"
terraform state pull | python3 -m json.tool 2>/dev/null | head -30 || terraform state pull | head -50
echo ""
echo "EXAM NOTE: sensitive = true values are PLAINTEXT in this JSON output."
echo "sensitive flag suppresses CLI display only — not state encryption."

echo ""
echo "--- 6. IMPORT demonstration ---"
echo "EXAM: terraform import syntax:"
echo "  terraform import <resource_address> <real_resource_id>"
echo ""
echo "EXAM TRAP: import does NOT generate .tf configuration."
echo "You must have the resource block written BEFORE running import."
echo "After import, 'terraform plan' will show differences until your"
echo ".tf config exactly matches the real resource attributes."

echo ""
echo "--- 7. REFRESH: Updates state, never .tf files ---"
echo "Running: terraform apply -refresh-only -auto-approve"
terraform apply -refresh-only -auto-approve 2>/dev/null || true
echo "State updated to match real infrastructure."
echo "Check: git diff *.tf  -> zero changes to configuration files"

echo ""
echo "=================================================================="
echo "State practice complete."
echo "Key distinction burned in:"
echo "  state rm -> orphan (infra lives)"
echo "  destroy  -> kill   (infra gone)"
echo "  import   -> adopt  (no .tf generated)"
echo "  refresh  -> sync   (.tf files NEVER touched)"
echo "=================================================================="
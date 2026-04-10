# sentinel/sentinel.hcl
# Policy set configuration for Terraform Cloud
# Upload the entire sentinel/ directory to your TFC organisation as a policy set.
#
# How to connect this policy set in Terraform Cloud:
#   1. Go to your TFC org → Settings → Policy Sets
#   2. Click "Connect a new policy set"
#   3. Connect to your VCS repo and set the Policies path to "sentinel/"
#   4. Choose which workspaces to apply it to (or "All workspaces")

policy "allowed-instance-types" {
  source            = "./allowed-instance-types.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "require-terraform-tag" {
  source            = "./require-terraform-tag.sentinel"
  enforcement_level = "soft-mandatory"
}

policy "cost-check" {
  source            = "./cost-check.sentinel"
  enforcement_level = "advisory"
}

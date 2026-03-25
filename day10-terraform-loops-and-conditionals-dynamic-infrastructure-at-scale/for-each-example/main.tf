# =============================================================
# Day 10 — for_each Examples
# =============================================================
# for_each keys resources on a VALUE (string or map key) rather
# than a numeric index. Removing one entry only affects that
# one resource — no destructive renumbering.
# =============================================================

# ── for_each with a set (simplest form) ──────────────────────
variable "user_names_set" {
  description = "IAM usernames as a set — order is irrelevant, keys are stable"
  type        = set(string)
  default     = ["alice", "bob", "charlie"]
}

resource "aws_iam_user" "set_users" {
  for_each = var.user_names_set
  name     = each.value   # each.key == each.value for sets

  tags = {
    ManagedBy = "Terraform"
  }
}

# If we remove "alice" from the set:
#   → Only aws_iam_user.set_users["alice"] is destroyed.
#   → bob and charlie are completely untouched. ✅

# ── for_each with a map (carry extra config per item) ─────────
variable "users" {
  description = "IAM users with per-user configuration"
  type = map(object({
    department = string
    admin      = bool
  }))
  default = {
    alice = { department = "engineering", admin = true }
    bob   = { department = "marketing",   admin = false }
    carol = { department = "devops",      admin = true }
  }
}

resource "aws_iam_user" "map_users" {
  for_each = var.users
  name     = each.key   # map key becomes the resource identifier

  tags = {
    Department = each.value.department
    IsAdmin    = each.value.admin
    ManagedBy  = "Terraform"
  }
}

# Attach admin policy only to admin users
resource "aws_iam_user_policy_attachment" "admin_policy" {
  for_each = { for name, cfg in var.users : name => cfg if cfg.admin }

  user       = aws_iam_user.map_users[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ── Outputs ───────────────────────────────────────────────────
output "set_user_arns" {
  description = "ARNs from set-based for_each (accessed by key)"
  value       = { for name, user in aws_iam_user.set_users : name => user.arn }
}

output "map_user_details" {
  description = "Name → ARN map for all users created from the map variable"
  value       = { for name, user in aws_iam_user.map_users : name => user.arn }
}

output "admin_users" {
  description = "Only the admin users and their ARNs"
  value = {
    for name, user in aws_iam_user.map_users : name => user.arn
    if var.users[name].admin
  }
}

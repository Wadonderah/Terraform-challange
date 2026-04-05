# =============================================================
# Day 10 — for Expressions
# =============================================================
# for expressions TRANSFORM collections inline. They do not
# create resources — they reshape data for outputs, locals,
# and resource arguments.
#
# Syntax:
#   List:  [for <item> in <collection> : <expression>]
#   Map:   {for <key>, <val> in <collection> : <key> => <expression>}
#   Filter: add `if <condition>` after the expression
# =============================================================


variable "user_names" {
  type    = set(string)
  default = ["alice", "bob", "charlie"]
}

variable "users" {
  type = map(object({
    department = string
    admin      = bool
  }))
  default = {
    alice = { department = "engineering", admin = true }
    bob   = { department = "marketing", admin = false }
    carol = { department = "devops", admin = true }
  }
}

resource "aws_iam_user" "example" {
  for_each = var.users
  name     = each.key
}

# ── List transformation ──

output "upper_names" {
  description = "All usernames in UPPERCASE — useful for display or S3 prefix naming"
  value       = [for name in var.user_names : upper(name)]
  # → ["ALICE", "BOB", "CHARLIE"]
}

output "prefixed_names" {
  description = "Names with an iam- prefix — for naming conventions"
  value       = [for name in var.user_names : "iam-${name}"]
  # → ["iam-alice", "iam-bob", "iam-charlie"]
}

# ── Map transformation ────

output "user_arns" {
  description = "username → ARN map — the most useful output for other modules to consume"
  value       = { for name, user in aws_iam_user.example : name => user.arn }
  # → { alice = "arn:aws:iam::123:user/alice", bob = "...", carol = "..." }
}

output "user_department_map" {
  description = "username → department — handy for tagging pipelines or cost allocation"
  value       = { for name, cfg in var.users : name => cfg.department }
  # → { alice = "engineering", bob = "marketing", carol = "devops" }
}

# ── Filtered transformation ──

output "admin_arns" {
  description = "ARNs of admin users only — used by policy attachment modules"
  value = {
    for name, user in aws_iam_user.example : name => user.arn
    if var.users[name].admin
  }
  # → { alice = "arn:...", carol = "arn:..." }   (bob excluded — not admin)
}

# ── Inline in a local (centralise logic) ───

locals {
  # Build a flat list of strings: "name:department"
  user_summary = [
    for name, cfg in var.users : "${name}:${cfg.department}"
  ]

  # Invert the map: department → list of usernames in that dept
  dept_to_users = {
    for dept in distinct([for cfg in var.users : cfg.department]) :
    dept => [for name, cfg in var.users : name if cfg.department == dept]
  }
}

output "user_summary_list" {
  description = "Flat list summarising each user — good for README generation"
  value       = local.user_summary
}

output "dept_to_users" {
  description = "Department → members map — useful for org-level reporting"
  value       = local.dept_to_users
}
